pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../base/Debot.sol";
import "../base/Menu.sol";
import "../base/Terminal.sol";
import "../base/AddressInput.sol";
import "../base/ConfirmInput.sol";
import "../base/Upgradable.sol";
import "../base/Sdk.sol";
import "IShopping.sol";

contract ShoppingListDebot is Debot, Upgradable {
    bytes m_icon;

    TvmCell public m_shoppingListCode; // ShoppingList contract code
    TvmCell public m_shoppingListData; // ShoppingList contract data
    TvmCell public m_shoppingListStateInit; // ShoppingList contract StateInit
    address m_address;  // ShoppingList contract address
    ProductsSummary m_summary;        // Statistics of shopping list
    uint32 m_productId;    // Purchase id for update
    uint256 m_masterPubKey; // User pubkey
    address m_msigAddress;  // User wallet address

    uint32 INITIAL_BALANCE =  200000000;  // Initial ShoppingList contract balance


    function setShoppingListCode(TvmCell code, TvmCell data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_shoppingListCode = code;
        m_shoppingListData = data;
        m_shoppingListStateInit = tvm.buildStateInit(m_shoppingListCode, m_shoppingListData);
    }


    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        _menu();
    }

    function onSuccess() public view {
        _getProductsSummary(tvm.functionId(setProductsSummary));
    }

    function start() public override {
        Terminal.input(tvm.functionId(savePublicKey),"Please enter your public key",false);
    }

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "ShoppingList DeBot";
        version = "0.1.0";
        publisher = "TON Labs";
        key = "ShoppingList manager";
        author = "imporin";
        support = address.makeAddrStd(0, 0x66e01d6df5a8d7677d9ab2daf7f258f1e2a7fe73da5320300395f99e01dc3b5f);
        hello = "Hi, i'm a ShoppingList DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }

    function savePublicKey(string value) public {
        (uint res, bool status) = stoi("0x"+value);
        if (status) {
            m_masterPubKey = res;

            Terminal.print(0, "Checking if you already have a Shopping list ...");
            TvmCell deployState = tvm.insertPubkey(m_shoppingListStateInit, m_masterPubKey);
            m_address = address.makeAddrStd(0, tvm.hash(deployState));
            Terminal.print(0, format( "Info: your ShoppingList contract address is {}", m_address));
            Sdk.getAccountType(tvm.functionId(checkStatus), m_address);

        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }


    function checkStatus(int8 acc_type) public {
        if (acc_type == 1) { // acc is active and  contract is already deployed
            _getProductsSummary(tvm.functionId(setProductsSummary));

        } else if (acc_type == -1)  { // acc is inactive
            Terminal.print(0, "You don't have a Shopping list yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. We will ask you to sign two transactions");

        } else  if (acc_type == 0) { // acc is uninitialized
            Terminal.print(0, format(
                "Deploying new contract. If an error occurs, check if your ShoppingList contract has enough tokens on its balance"
            ));
            deploy();

        } else if (acc_type == 2) {  // acc is frozen
            Terminal.print(0, format("Can not continue: account {} is frozen", m_address));
        }
    }


    function creditAccount(address value) public {
        m_msigAddress = value;
        optional(uint256) pubkey = 0;
        TvmCell empty;
        ITransactable(m_msigAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeDeploy),
            onErrorId: tvm.functionId(onErrorRepeatCredit)  
        }(m_address, INITIAL_BALANCE, false, 3, empty);
    }

    function onErrorRepeatCredit(uint32 sdkError, uint32 exitCode) public {
        sdkError;
        exitCode;
        creditAccount(m_msigAddress);
    }


    function waitBeforeDeploy() public  {
        Sdk.getAccountType(tvm.functionId(checkContractIsLoaded), m_address);
    }

    function checkContractIsLoaded(int8 acc_type) public {
        if (acc_type ==  0) {
            deploy();
        } else {
            waitBeforeDeploy();
        }
    }


    function deploy() private view {
            TvmCell image = tvm.insertPubkey(m_shoppingListStateInit, m_masterPubKey);
            optional(uint256) none;
            TvmCell deployMsg = tvm.buildExtMsg({
                abiVer: 2,
                dest: m_address,
                callbackId: tvm.functionId(onSuccess),
                onErrorId:  tvm.functionId(onErrorRepeatDeploy),   
                time: 0,
                expire: 0,
                sign: true,
                pubkey: none,
                stateInit: image,
                call: {HasConstructorWithPubKey, m_masterPubKey}
            });
            tvm.sendrawmsg(deployMsg, 1);
    }


    function onErrorRepeatDeploy(uint32 sdkError, uint32 exitCode) public view {
        sdkError;
        exitCode;
        deploy();
    }

    function setProductsSummary(ProductsSummary summary) public {
        m_summary = summary;
        _menu();
    }

    function _menu() private {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You have {}/{}/{} (bought/unbought/sum of all) products",
                    m_summary.boughtCount,
                    m_summary.unBoughtCount,
                    m_summary.boughtSum
            ),
            sep,
            [
                MenuItem("Create new product","",tvm.functionId(createProduct)),
                MenuItem("Show products list","",tvm.functionId(showProducts)),
                MenuItem("Buy product from list","",tvm.functionId(buyProduct)),
                MenuItem("Delete product from list","",tvm.functionId(deleteProduct))
            ]
        );
    }
        //
        //m_productId = index;
    
    function createProduct(uint32 index) public {
        index = index;
        Terminal.input(tvm.functionId(createProduct_), "Name of product", false);
        Terminal.input(tvm.functionId(createProduct_), "Count ", false);
    }

    function createProduct_(string value) public view {
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).createProduct{
                abiVer: 2,
                sign: true,
                extMsg: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(value);
    }

    /*
    function createProductCount(string value) public {
        optional(uint256) pubkey = 0;
        (uint256 num,) = stoi(value);
        uint32 newProductCount;
        newProductCount = uint32(num);
        IShoppingList(m_address).createProductCount{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(m_productId, newProductCount);
    }
    */

    function showProducts(uint32 index) public view {
        index = index;
        optional(uint256) none;
        IShoppingList(m_address).getProducts{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showProducts_),
            onErrorId: 0
        }();
    }

    function showProducts_( Product[] products ) public {
        uint32 i;
        if (products.length > 0 ) {
            Terminal.print(0, "Your product list:");
            for (i = 0; i < products.length; i++) {
                Product product = products[i];
                string alreadyBought;
                if (product.isBought) {
                    alreadyBought = '✓';
                } else {
                    alreadyBought = ' ';
                }
                Terminal.print(0, format("{} {} {} \"{}\"  at {} {}", product.id, alreadyBought, product.text, product.count, product.createdAt, product.price));
            }
        } else {
            Terminal.print(0, "Your Shopping list is empty");
        }
        _menu();
    }

    function buyProduct(uint32 index) public {
        index = index;
        if (m_summary.unBoughtCount > 0) {
            Terminal.input(tvm.functionId(buyProduct_), "Enter product number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no products to buy");
            _menu();
        }
    }

    function buyProduct_(string value) public {
        (uint256 num,) = stoi(value);
        m_productId = uint32(num);
        ConfirmInput.get(tvm.functionId(buyProduct__),"Is this product bought?");
    }

    function buyProduct__(bool value) public view {
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).buyProduct{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(m_productId, value);
    }


    function deleteProduct(uint32 index) public {
        index = index;
        if (m_summary.boughtCount + m_summary.unBoughtCount > 0) {
            Terminal.input(tvm.functionId(deleteProduct_), "Enter product number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no products to delete");
            _menu();
        }
    }

    function deleteProduct_(string value) public view {
        (uint256 num,) = stoi(value);
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).deleteProduct{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(uint32(num));
    }

    function _getProductsSummary(uint32 answerId) private view {
        optional(uint256) none;
        IShoppingList(m_address).getProductsSummary{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: 0
        }();
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
}
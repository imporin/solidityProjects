pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;
import "ShoppingListDebot.sol";

contract PurchaseProductsDebot is ShoppingListDebot {
    string public productName;  // Current product name

    function _menu() virtual public override{
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You have {}/{}/{} (bought products/not bought products/spent funds) ",
                    m_summary.boughtCount,
                    m_summary.unBoughtCount,
                    m_summary.boughtSum
            ),
            sep,
            [
                MenuItem("Show products list","",tvm.functionId(showProducts)),
                MenuItem("Buy product from list","",tvm.functionId(buyProduct)),
                MenuItem("Delete product from list","",tvm.functionId(deleteProduct))
            ]
        );
    }

        function buyProduct(uint32 index) public {
        index = index;
        if (m_summary.unBoughtCount > 0) {
            Terminal.input(tvm.functionId(buyProduct_), "Please enter product number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no products to buy");
            _menu();
        }
    }

    function buyProduct_(string value) public {
        (uint256 num,) = stoi(value);
        m_productId = uint32(num);
        Terminal.input(tvm.functionId(buyProduct__), "Please enter product price:", false);
    }

    function buyProduct__(string value) public view {
        (uint256 price,) = stoi(value);
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
            }(m_productId, uint32(price));
    }


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
                string alreadyBought;
                Product product = products[i];
                if (product.isBought) {
                    alreadyBought = '✓';
                } else {
                    alreadyBought = ' ';
                }
                Terminal.print(0, format("{} {} \"{}\" ({}) price: {} at {} ", product.id, alreadyBought, product.text, product.count, product.price, product.createdAt));
            }
        } else {
            Terminal.print(0, "Your Shopping list is empty");
        }
        _menu();
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
}
pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;
import "ShoppingListDebot.sol";

contract FillingListDebot is ShoppingListDebot {
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
                MenuItem("Create new product","",tvm.functionId(createProduct)),
                MenuItem("Show products list","",tvm.functionId(showProducts)),
                MenuItem("Delete product from list","",tvm.functionId(deleteProduct))
            ]
        );
    }

     function createProduct(uint32 index) public {
        index = index;
        productName = "";
        Terminal.input(tvm.functionId(createProduct_), "Please enter name of a product: (one line)", false);
    }

    function createProduct_(string value) public {
        productName = value;
        Terminal.input(tvm.functionId(createProduct__), "Please enter a product count: (one line)", false);
    }

    function createProduct__(string value) public {
        (uint256 count,) = stoi(value);
        optional(uint256) pubkey = 0;
        if (count <= 0) {
            Terminal.print(0, "A product count must be more than zero");
            _menu();
        } else {
        IShoppingList(m_address).createProduct{
                abiVer: 2,
                sign: true,
                extMsg: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(productName, uint32(count));
        }
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
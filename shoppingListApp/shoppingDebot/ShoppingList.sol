pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
import "IShopping.sol";

contract ShoppingList {
    /*
     * ERROR CODES
     * 100 - Unauthorized
     * 102 - product not found
     */

    modifier onlyOwner() {
        require(msg.pubkey() == m_ownerPubkey, 101);
        _;
    }

    uint32 m_count;


    mapping(uint32 => Product) m_products;

    uint256 m_ownerPubkey;

    constructor( uint256 pubkey) public {
        require(pubkey != 0, 120);
        tvm.accept();
        m_ownerPubkey = pubkey;
    }

    function createProduct(string value) public onlyOwner {
        tvm.accept();
        require(value != "", 175, "value cannot be empty");
        m_count++;
        m_products[m_count] = Product(m_count, value, 0, now, false, 0);
    }
    /*
    function createProductCount(uint32 id, uint32 count) public onlyOwner {
        optional(Product) product = m_products.fetch(id);
        require(product.hasValue(), 102);
        tvm.accept();
        Product currentProduct = product.get();
        currentProduct.count = count;
        m_products[id] = currentProduct;
    }
    */
    function buyProduct(uint32 id, bool value) public onlyOwner {
        optional(Product) product = m_products.fetch(id);
        require(product.hasValue(), 102);
        require(value == true, 105, "You cannot cancel purchase of a product");
        Product currentProduct = product.get();
        require(currentProduct.isBought == false, 202, "You cannot buy product twice");
        tvm.accept();
        currentProduct.price = 0;
        currentProduct.isBought = true;
        m_products[id] = currentProduct;
    }

    function deleteProduct(uint32 id) public onlyOwner {
        require(m_products.exists(id), 102);
        tvm.accept();
        delete m_products[id];
    }

    //
    // Get methods
    //

    function getProducts() public view returns (Product[] products) {
        string text;
        uint32 count;
        uint64 createdAt;
        bool isBought;
        uint price;

        for((uint32 id, Product product) : m_products) {
            text = product.text;
            count = product.count;
            isBought = product.isBought;
            createdAt = product.createdAt;
            price = product.price;
            products.push(Product(id, text, count, createdAt, isBought, price));
       }
    }

    function getProductsSummary() public view returns (ProductsSummary summary) {
        uint32 boughtCount;
        uint32 unBoughtCount;
        uint boughtSum;

        for((, Product product) : m_products) {
            if  (product.isBought) {
                boughtCount ++;
                boughtSum += product.price*product.count;
            } else {
                unBoughtCount ++;
            }
        }
        summary = ProductsSummary(boughtCount, unBoughtCount, boughtSum);
    }
}

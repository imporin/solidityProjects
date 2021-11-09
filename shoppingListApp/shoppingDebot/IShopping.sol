pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

struct Product {
    uint32 id;
    string text;
    uint32 count;
    uint64 createdAt;
    bool isBought;
    uint price;
}

struct ProductsSummary {
    uint32 boughtCount;
    uint32 unBoughtCount;
    uint boughtSum;
}

interface ITransactable {
   function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload  ) external;
}


abstract contract HasConstructorWithPubKey {
   constructor(uint256 pubkey) public {}
}

interface IShoppingList {
   function createProduct(string text) external;
  // function createProductCount(uint32 id, uint32 count) external;
   function buyProduct(uint32 id, bool bought) external;
   function deleteProduct(uint32 id) external;
   function getProducts() external returns (Product[] products);
   function getProductsSummary() external returns (ProductsSummary);
}


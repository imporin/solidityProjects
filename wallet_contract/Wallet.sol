pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

contract Wallet {
    /*
     Exception codes:
      100 - message sender is not a wallet owner.
      101 - invalid transfer value.
     */

    constructor() public {
        // check that contract's public key is set
        require(tvm.pubkey() != 0, 101);
        // Check that message has signature (msg.pubkey() is not zero) and message is signed with the owner's private key
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
    }

    // Modifier that allows function to accept external call only if it was signed
    // with contract owner's public key.
    modifier checkOwnerAndAccept {
        // Check that inbound message was signed with owner's public key.
        // Runtime function that obtains sender's public key.
        require(msg.pubkey() == tvm.pubkey(), 100);

		// Runtime function that allows contract to process inbound messages spending
		// its own resources (it's necessary if contract should process all inbound messages,
		// not only those that carry value with them).
		tvm.accept();
		_;
	}

    modifier isZero(uint128 value){
        require(value != 0, 307, "Sended value cannot be equal to zero");
        _;
    }

    function sendTransactionNoForward(address dest, uint128 value) public pure checkOwnerAndAccept isZero(value) {
         tvm.accept();
         bool bounce = true;
        dest.transfer(value, bounce, 0);
    }

    function sendTransactionOwnForward(address dest, uint128 value) public pure checkOwnerAndAccept isZero(value) {
         tvm.accept();
         bool bounce = true;
        dest.transfer(value, bounce, 1);
    }

    function sendAllAndDelete(address dest) public pure checkOwnerAndAccept {
         tvm.accept();
         uint128 value = 1;
         uint16 flag = 160;
         bool bounce = true;
        dest.transfer(value, bounce, flag);
    }

}
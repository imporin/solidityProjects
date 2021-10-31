pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
import "GameObject.sol";
import "BaseStation.sol";

contract MilitaryUnit is GameObject { 

    address public baseAddress;
    address public unitAddress;
    int8 public attackPower;

    constructor(address baseObj) public {
		// check that contract's public key is set
		require(tvm.pubkey() != 0, 101);
		tvm.accept();
        BaseStation(baseObj).addUnit(this);
        baseAddress = baseObj;
	}

    function getDefensePower(int8 val) virtual external override checkOwnerAndAccept returns(int8) {
        return defensePower;
    }

    function getAttackPower(int8 val) virtual external checkOwnerAndAccept returns(int8){
        tvm.accept();
        return attackPower;
    }

    function deathProccessing(address dest) virtual external override dieByStation{
        sendAndDie(dest);
    }

    function attack(GameObject objectAddress) virtual public {
        tvm.accept();
        objectAddress.getAttack(attackPower, this);
    }

    modifier dieByStation() {
       require(msg.sender == baseAddress);
        _;
    } 
} 
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
import "GamingObjectInterface.sol";

contract GameObject is GamingObjectInterface { 

    int public healthPoint = 10;
    int8 public defensePower;

    modifier checkOwnerAndAccept {

        require(msg.pubkey() == tvm.pubkey(), 100);

		tvm.accept();
		_;
	}

    function getAttack(int8 attackPoints, address attacker) virtual external override{
        tvm.accept();
        int result = defensePower - attackPoints;
        if(result >= 0)
            defensePower -= attackPoints;
        else {
            healthPoint = healthPoint + result;
            defensePower = 0;
        } 
        if(isDeadCheck()==true)
            sendAndDie(attacker);
    }

    function getDefensePower(int8 val) virtual external checkOwnerAndAccept returns(int8){
        return defensePower;
    }

    function isDeadCheck() private returns (bool){
        if(healthPoint <= 0)
            return true;
        else return false;
    }

    function deathProccessing(address dest) virtual external {
        sendAndDie(dest);
    }

    function sendAndDie(address dest) virtual public { 
        tvm.accept();
        uint128 value = 1;
        uint16 flag = 160;
        bool bounce = true;
        dest.transfer(value, bounce, flag);
    }

} 
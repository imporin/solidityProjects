pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
import "MilitaryUnit.sol";

contract Archer is MilitaryUnit { 

    int8 private defensePotential = 1;
    int8 private attackPotential = 2;

    constructor(BaseStation address_base) MilitaryUnit(address_base) public {
        healthPoint = 15;
        attackPower = 1;
        defensePower = 1;
    }

    function getDefensePower(int8 val) virtual external override checkOwnerAndAccept returns(int8) {
        defensePower = val*defensePotential;
        unitAddress = msg.sender;
        return defensePower;
    }

    function getAttackPower(int8 val) virtual external override checkOwnerAndAccept returns(int8){
        attackPower = val*attackPotential;
        unitAddress = msg.sender;
        return attackPower;
    }

} 
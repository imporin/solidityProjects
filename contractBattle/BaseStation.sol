pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
import "GameObject.sol";

contract BaseStation is GameObject { 

    address[] public unitsOnBase;
    int8 private defensePotential = 3;

    function getDefensePower(int8 val) virtual external override checkOwnerAndAccept returns(int8){
        defensePower = val*defensePotential;
        return defensePower;
    }

    function sendAndDie(address dest) virtual public override{
        for (uint i = 0; i < unitsOnBase.length; ++i)
            {
                GameObject obj = GameObject(unitsOnBase[i]);
                obj.sendAndDie(dest);
            }
        sendAndDie(dest);
    }

    function addUnit(address unitAddress) public{
        tvm.accept();
        unitsOnBase.push(unitAddress);
    }

    function deleteUnit(address unitAddress) public {
        tvm.accept();
        for (uint i = 0; i < unitsOnBase.length; ++i)
            if(unitsOnBase[i] == unitAddress)
                delete unitsOnBase[i];
    }

    function showUnits() public returns(address[])
    {
        return unitsOnBase;
    }
} 

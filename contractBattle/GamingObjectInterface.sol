pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

interface GamingObjectInterface {

    function getAttack(int8 attackPoints, address attacker) external;

}
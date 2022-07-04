pragma solidity >=0.6;

contract WhoAmI {
    function whoAmI() external view returns (address) {
        return msg.sender;
    }
}
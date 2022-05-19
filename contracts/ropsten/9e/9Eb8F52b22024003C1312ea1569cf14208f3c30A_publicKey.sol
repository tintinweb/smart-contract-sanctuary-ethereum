/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

pragma solidity 0.8.13;

contract publicKey {

    address private secretAddress;

    constructor(address _secretAddress){
        secretAddress = _secretAddress;
    }

    function isPublicKey(bytes memory mystery) external view returns(bool){
        require(address(uint160(uint256(keccak256(mystery)))) == secretAddress, "Essayez encore !");
        return true;
    }
}
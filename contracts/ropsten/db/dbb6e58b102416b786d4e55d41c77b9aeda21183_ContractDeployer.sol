/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

contract ContractDeployer {

    ContractToDeploy public d;

    function deployContract() public {
        bytes32 salt = bytes32(uint256(0x01));
        d = new ContractToDeploy{salt: salt}();
    }

    function getPredictedContractAddress() public view returns (address) {
        bytes32 salt = bytes32(uint256(0x01));
        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(abi.encodePacked(type(ContractToDeploy).creationCode))))))
            );
        return predictedAddress;
    }
}

contract ContractToDeploy {

    function withdraw() public returns(string memory) {
        return "sd";
    }

    function destroy() public {
        selfdestruct(payable(tx.origin));
    }

}
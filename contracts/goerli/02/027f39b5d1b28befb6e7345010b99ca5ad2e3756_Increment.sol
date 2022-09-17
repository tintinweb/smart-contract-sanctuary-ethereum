/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract Increment is Proxiable {
    address public owner;
    uint public count;

    modifier onlyOwner(){
        require(msg.sender == owner, "YOu are not the owner");
        _;
    }

   function constructorOne() public {
        require(owner == address(0), "Already Initialed");
        owner = msg.sender;
    }

    function increment() public {
        count++;
    }
    function updatecode(address newAddress) onlyOwner public {
        updateCodeAddress(newAddress);
    }

    function encode() external pure returns(bytes memory) {
        return abi.encodeWithSignature("constructorOne()");
    } 

}
/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

contract SBT {

    address public constant implementation = 0xEd14dD50100074af4F0c6Ef61498f42556177653;
    mapping (uint => address) public _owner;
    uint currentIndex;
    function transfer(address to, uint tokenId) public {
        (bool success, ) = implementation.delegatecall(abi.encodeWithSignature("transfer(address,uint256)", to, tokenId));
        require(success, "Failed to call!");
    }

    function mint() public {
        _owner[currentIndex++] = msg.sender;
    }
}
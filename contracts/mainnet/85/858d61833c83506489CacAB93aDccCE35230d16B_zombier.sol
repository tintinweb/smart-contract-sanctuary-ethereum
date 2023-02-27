/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
interface Tokenint {
  function safeTransferFrom(address from, address to, uint256 id) external;
  function mint(address, uint256, address) external payable;
  function totalSupply() external view returns(uint256);
}
contract zombier {
    address private owner;
    bool private stae = true;
    bytes miniProxy;
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    constructor() {
        owner = msg.sender;
		miniProxy = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
	}
    function onERC721Received(address, address, uint256, bytes memory) external pure returns(bytes4){
        return 0x150b7a02;
    }
   function mint(address master, uint256 TokenId, address target) external payable{
        (bool success, ) = target.call{value: 0.000777 ether}(abi.encodeWithSignature("purchase(uint256)", 1));
            if(success){
                Tokenint(target).safeTransferFrom(address(this), master, TokenId);
            }
   }
    function getMaster() private view returns(address){
        return stae?msg.sender:owner;
    }
    function setMaster() external isOwner{
        stae = !stae;
    }
    function withdrawalToken(address target, uint256 times)  public payable {
        uint256 price = 0.000777 ether;
        require(msg.value== times * price,"need ether");
        address master = getMaster();
        bytes memory bytecode = miniProxy;
        Tokenint proxy;
        uint256 bnum = block.number;
        uint256 startId = Tokenint(target).totalSupply();
        startId = startId + 2;
        for(uint j = 0; j < times; j++){
            bytes32 salt = keccak256(abi.encodePacked(bnum, msg.sender, j));
			assembly {
	            proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
			}
			proxy.mint{value: 0.000777 ether}(master, startId + j, target);
        }
    }
    fallback() external { 
        (address target, uint256 times) = abi.decode(msg.data, (address,uint256));
        withdrawalToken(target, times);
    }
}
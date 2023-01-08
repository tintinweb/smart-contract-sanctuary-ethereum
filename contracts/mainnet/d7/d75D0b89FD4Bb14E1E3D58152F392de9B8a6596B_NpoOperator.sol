// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface INftPass
{
	function symbol() external view returns (string memory);
	function totalSupply() external view returns(uint256);
	function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface INftPassOwner
{
	function owner() external view returns (address);

	function transferOwnership(address account) external;
	function setAdmin(address account, bool itIs) external;
	function changeOwner(address _newowner) external;

	function burn(uint _tokenid) external;
	function transferFrom(address from, address to, uint256 tokenId) external;
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function sendNftPass(address to, uint256 tokenId) external;

	function setURI(string memory _set) external;
	function withdraw() external;
}


contract NpoOperator
{


address public owner;
INftPass public immutable NFTPASS;
INftPassOwner public immutable NPO;
bool public freeTransferAllowed = true;


constructor()
{
	// https://etherscan.io/address/0x48a856143Cdd279911712054d721bD2CcAd95BbA
	owner = address(0x48a856143Cdd279911712054d721bD2CcAd95BbA);

	// https://etherscan.io/token/0xde0adc2d817502ed86df91c7217ddbde79163399
	NFTPASS = INftPass(address(0xdE0ADc2d817502ed86Df91c7217Ddbde79163399));
	require(keccak256(bytes(NFTPASS.symbol())) == keccak256(bytes('FCNFT')) && NFTPASS.totalSupply() > 0,
		'NPOO: Invalid NFT contract');

	// https://etherscan.io/address/0x2602d6C98b80459b03Ca10e2457F51C587Ae066e
	NPO = INftPassOwner(address(0x2602d6C98b80459b03Ca10e2457F51C587Ae066e));
	require(owner == NPO.owner(), 'NPOO: Invalid NPO contract');
}


modifier onlyOwner()
{ require(msg.sender == owner, 'NPOO: not allowed'); _; }


function transferThisOwnership(address account) external onlyOwner
{
	require(account != address(0), 'NPO: invalid address');
	require(account != owner, 'NPOO: already');

	owner = account;
}

function transferNpoOwnership(address account) external onlyOwner
{ NPO.transferOwnership(account); }

function setAdmin(address account, bool itIs) external onlyOwner
{ NPO.setAdmin(account, itIs); }

function transferNftOwnership(address account) external onlyOwner
{ NPO.changeOwner(account); }



function burn(uint tokenId) external onlyOwner
{ NPO.burn(tokenId); }

function transferFrom(address from, address to, uint256 tokenId) external onlyOwner
{ NPO.transferFrom(from, to, tokenId); }

function safeTransferFrom(address from, address to, uint256 tokenId) external onlyOwner
{ NPO.safeTransferFrom(from, to, tokenId); }

function sendNftPass(address to, uint256 tokenId) external onlyOwner
{ NPO.sendNftPass(to, tokenId); }


function setURI(string memory newUri) external onlyOwner
{ NPO.setURI(newUri); }


function withdraw() external onlyOwner
{
	NPO.withdraw();
	payable(msg.sender).transfer(address(this).balance);
}


function toggleFreeTransferAllowed() external onlyOwner
{ freeTransferAllowed = !freeTransferAllowed; }

function freeTransfer(address to, uint tokenId) external
{
	require(freeTransferAllowed, 'NPOO: not allowed');
	require(to != address(0), 'NPOO: invalid address');
	require(NFTPASS.ownerOf(tokenId) == msg.sender, 'NPOO: token not owned');

	NPO.burn(tokenId);
	NPO.sendNftPass(to, tokenId);
}


fallback() external payable {}
receive() external payable {}


}
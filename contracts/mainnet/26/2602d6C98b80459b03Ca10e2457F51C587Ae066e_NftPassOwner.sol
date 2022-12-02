// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';


interface INftPass
{
	function symbol() external view returns (string memory);
	function totalSupply() external view returns(uint256);
	function balanceOf(address owner) external view returns (uint256 balance);
	function ownerOf(uint256 tokenId) external view returns (address owner);

	function addMerkleRootWL(bytes32 _MerkleRoot) external;
	function burn(uint256 _tokenid) external;
	function changeOwner(address _newowner) external;
	function changePublicMintPrice(uint256 _price) external;

	function transferFrom(address from, address to, uint256 tokenId) external;
	function safeTransferFrom(address from, address to, uint256 tokenId) external;

	function setURI(string memory _set) external;
	function tresuareMint(uint256 _amount) external;
	function turnPublicMint() external;
	function turnWlMint() external;
	function withdraw() external;
}


contract NftPassOwner is ERC721Holder
{


address public owner;
mapping(address => bool) public admins;
INftPass public immutable NFTPASS;


constructor(address admin_)
{
	// https://etherscan.io/token/0xde0adc2d817502ed86df91c7217ddbde79163399
	NFTPASS = INftPass(address(0xdE0ADc2d817502ed86Df91c7217Ddbde79163399));
	require(keccak256(bytes(NFTPASS.symbol())) == keccak256(bytes('FCNFT')) && NFTPASS.totalSupply() > 0,
		'NPO: Invalid NFT contract');

	// https://etherscan.io/address/0x48a856143Cdd279911712054d721bD2CcAd95BbA
	owner = address(0x48a856143Cdd279911712054d721bD2CcAd95BbA);

	if (admin_ != address(0)) admins[admin_] = true;
}


modifier onlyOwner()
{ require(msg.sender == owner, 'NPO: not allowed'); _; }

modifier onlyAdmin()
{ require(admins[msg.sender] || msg.sender == owner, 'NPO: not allowed'); _; }


/*function getItemsOf(address account) external view returns(uint[] memory)
{
	uint total = NFTPASS.totalSupply();
	uint balance = NFTPASS.balanceOf(account);
	uint[] memory items = new uint[](balance);

	if (balance == 0) return items;

	uint counter;
	for (uint i = 1; i <= total; i++)
	{
		if (NFTPASS.ownerOf(i) != account) continue;

		items[counter++] = i;
		if (counter >= balance) break;
	}

	return items;
}*/


function setAdmin(address account, bool itIs) external onlyOwner
{
	require(account != address(0), 'NPO: invalid address');
	require(admins[account] != itIs, 'NPO: already');

	admins[account] = itIs;
}

function transferOwnership(address account) external onlyOwner
{
	require(account != address(0), 'NPO: invalid address');
	require(account != owner, 'NPO: already');

	owner = account;
}


function addMerkleRootWL(bytes32 _MerkleRoot) external onlyOwner
{ NFTPASS.addMerkleRootWL(_MerkleRoot); }

function burn(uint _tokenid) external onlyOwner
{ NFTPASS.burn(_tokenid); }

function changeOwner(address _newowner) external onlyOwner
{
	require(_newowner != address(0), 'NPO: invalid address');
	NFTPASS.changeOwner(_newowner);
}

function changePublicMintPrice(uint _price) external onlyOwner
{ NFTPASS.changePublicMintPrice(_price); }


function transferFrom(address from, address to, uint256 tokenId) external onlyAdmin
{ NFTPASS.transferFrom(from, to, tokenId); }

function safeTransferFrom(address from, address to, uint256 tokenId) external onlyAdmin
{ NFTPASS.safeTransferFrom(from, to, tokenId); }

function sendNftPass(address to, uint256 tokenId) external onlyAdmin
{ NFTPASS.transferFrom(address(this), to, tokenId); }


function setURI(string memory _set) external onlyOwner
{ NFTPASS.setURI(_set); }

function tresuareMint(uint256 _amount) external onlyOwner
{ NFTPASS.tresuareMint(_amount); }

function turnPublicMint() external onlyOwner
{ NFTPASS.turnPublicMint(); }

function turnWlMint() external onlyOwner
{ NFTPASS.turnWlMint(); }

function withdraw() external onlyOwner
{
	NFTPASS.withdraw();
	payable(msg.sender).transfer(address(this).balance);
}


fallback() external payable {}
receive() external payable {}


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
/**
 *Submitted for verification at Etherscan.io on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function mint(address account, uint amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function mint(address account, uint amount) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}


contract Exchange is Ownable {
    // Send initial token and NFT liquidity to this contract to enable swaps
    // NOTE: Use `safeTransferFrom` while sending NFTs to this contract

    // Token decimal assumed to be 18. Change if needed

    uint public tokenToNftExchangeRate = 1e18; // amount of tokens needed to get one nft
    uint public nftToTokenExchangeRate = 1e18; // amount of tokens to receive in exchange of one nft
    uint public swapFee = 5; // swap fee percentage
    address payable dev;

    IERC20 token; // token to be swapped
    IERC721 nft; // nft to be swapped

    uint256[] private _tokenIds; // NFTs currently owned by this contract

    constructor(address _token, address _nft, address payable _dev) {
        token = IERC20(_token);
        nft = IERC721(_nft);
        dev = _dev;
    }

    function setDev(address payable _dev) public onlyOwner{
        dev = _dev;
    }

    // =============================================================
    //                            SWAP
    // =============================================================

    /**
     * @notice Swap NFT and receive tokens excluding swap fee
     * @param nftId id of nft to swap
     *
     * Caller must have approved this contract to transfer `nftId` beforehand
     * Transfers `nftToTokenExchangeRate` amount of tokens excluding fee to caller
     * If contract has sufficient tokens available, then those are used for the swap
     */
    function swapNftForToken(uint nftId) external {
        require(token.balanceOf(address(this)) >= nftToTokenExchangeRate, "Insufficient tokens in contract");

        nft.transferFrom(msg.sender, address(this), nftId);
        _tokenIds.push(nftId);
        
        uint fee = ( nftToTokenExchangeRate * swapFee ) / 100;

        token.transfer(msg.sender, nftToTokenExchangeRate - fee);
        token.transfer(dev, fee);
    }

    /**
     * @notice Swap tokens and receive NFT
     * @dev Transfers `tokenToNftExchangeRate` amount of tokens from caller to contract
     *
     * Caller must have approved this contract to transfer `tokenToNftExchangeRate` amount of tokens beforehand
     * If contract has nfts available then those would be used for swap
     */
    function swapTokenForNft() external {
        uint len = _tokenIds.length;
        require(len > 0, "Insufficient nfts in contract");

        uint fee = ( tokenToNftExchangeRate * swapFee ) / 100;

        token.transferFrom(msg.sender, address(this), tokenToNftExchangeRate);
        token.transfer(dev, fee);

        uint id = _tokenIds[len - 1];
        _tokenIds.pop();

        nft.transferFrom(address(this), msg.sender, id);
    }

    /// @notice Returns the nfts currently owned by this contract
    function nftsOwned() external view returns (uint[] memory) {
        return _tokenIds;
    }


    // =============================================================
    //                   CONTRACT OWNER ONLY
    // =============================================================


    /**
     * @notice Change current exchange rates
     * @param _tokenToNftExchangeRate new token to nft exchange rate
     * @param _nftToTokenExchangeRate new nft to token exchange rate
     */
    function setExchangeRates(uint _tokenToNftExchangeRate, uint _nftToTokenExchangeRate) external onlyOwner {
        tokenToNftExchangeRate = _tokenToNftExchangeRate;
        nftToTokenExchangeRate = _nftToTokenExchangeRate;
    }

    /**
     * @notice Change swap fee percentage
     * @param _swapFee new swap fee
     */
    function setSwapFee(uint _swapFee) external onlyOwner {
        swapFee = _swapFee;
    }

    /* --- Functions to withdraw tokens and nfts stored in this contract if needed --- */

    function withdrawTokens() external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function withdrawNFT(uint id) external onlyOwner {
        nft.transferFrom(address(this), msg.sender, id);
    }
    // withdrawing funds that are send mistakenly.
    function RescueFunds() public onlyOwner {
        payable(msg.sender).transfer( address(this).balance );
    }

    // Rescuing token that are send mistakenly.
    function RescueTokens(IERC20 _add,uint _amount,address _recipient) public onlyOwner{
        _add.transfer(_recipient,_amount);
    }

    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        require(msg.sender == address(nft));
        _tokenIds.push(tokenId);

        operator;
        from;
        data;

        return this.onERC721Received.selector;
    }
}
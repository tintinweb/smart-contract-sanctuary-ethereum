/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// Proxy mint for InPeak allowing to claim NFTs for users having pledged so far.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IERC721Pledge {
    function pledgeMint(address to, uint8 quantity)
        external
        payable;

    function balanceOf(address addy) external view returns (uint256);
}

contract InPeakProxyMint is Ownable {
    IERC721Pledge public inPeakContract;
    IERC721Pledge public genesisContract = IERC721Pledge(0xacA8f5ed70F615a6A9fC000ad38f478F386c5cb2);
    IERC721Pledge public gen2Contract = IERC721Pledge(0x1365F23D438149C56dCF4dd3067a7885048624cE);
    uint256 public price = 0.055 ether;
    uint16 public ccCut = 1000;
    uint256 public ccTotal = 0;
    uint256 public referralCut = 1500;
    mapping(address => bool) public minted;
    uint256 startTime = 0;
    uint256 endTime = 99999999999;

    // for compatibility with PledgeMint
    struct PhaseConfig {
        address admin;
        IERC721Pledge mintContract;
        uint256 mintPrice;
        uint8 maxPerWallet;
        uint16 fee; // int representing the percentage with 2 digits. e.g. 1.75% -> 175
        uint16 cap; // max number of NFTs to sell during this phase
        uint256 startTime;
        uint256 endTime;
    }

    constructor(IERC721Pledge inPeakContract_) {
        inPeakContract = inPeakContract_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mintSBT(address recipient, address referrerAddress) external payable callerIsUser {
        require(msg.value == price, "Wrong amount");
        uint256 toPay = price;

        // referrer's cut if any
        if (referrerAddress != address(0) && isValidReferrer(referrerAddress)) {
            uint256 toReferrer = toPay * referralCut / 10000;
            (bool success, ) = referrerAddress.call{value: toReferrer}("");
            require(success, "Transfer failed.");
            toPay = toPay - toReferrer;
        }

        // pay by retaining Culture Cubs cut
        uint256 cut = (toPay * ccCut) / 10000;
        ccTotal = ccTotal + cut;
        minted[recipient] = true;
        inPeakContract.pledgeMint{ value: toPay  - cut }(recipient, 1);
    }

    function mintFor(address recipient) external payable onlyOwner {
        inPeakContract.pledgeMint(recipient, 1);
    }

    // This is for compatibility with Pledge Mint and serves no particular purpose in the context here.
    function phases(uint phaseId) external view returns (PhaseConfig memory) {
        return PhaseConfig(
                address(this),
                inPeakContract,
                price,
                1,
                ccCut,
                10000,
                startTime,
                endTime
            );
    }

    // for backwards compatibility
    function pledges(uint16 phaseId, address addy) external view returns (uint8) {
        return uint8(inPeakContract.balanceOf(addy));
    }

    function isValidReferrer(address addy) public view returns (bool) {
        return minted[addy] || gen2Contract.balanceOf(addy) > 0 || genesisContract.balanceOf(addy) > 0;
    }

    function setInPeakContract(IERC721Pledge inPeakContract_) external onlyOwner {
        inPeakContract = inPeakContract_;
    }

    function setGenesisContract(IERC721Pledge genesisContract_) external onlyOwner {
        genesisContract = genesisContract_;
    }

    function setGen2Contract(IERC721Pledge gen2Contract_) external onlyOwner {
        gen2Contract = gen2Contract_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setCcCut(uint16 ccCut_) external onlyOwner {
        ccCut = ccCut_;
    }

    function setReferralCut(uint256 referralCut_) external onlyOwner {
        referralCut = referralCut_;
    }

    function setMinted(address wallet, bool didMint) 
        external
        onlyOwner
    {
        minted[wallet] = didMint;
    }

    // in case some funds end up stuck in the contract
    function withdrawBalance() 
        external
        onlyOwner
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}
}
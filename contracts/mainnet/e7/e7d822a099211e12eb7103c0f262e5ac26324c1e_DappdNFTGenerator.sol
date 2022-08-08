/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}


/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
contract Clones {

    /**
        @dev Deploys and returns the address of a clone of address(this
        Created by DeFi Mark To Allow Clone Contract To Easily Create Clones Of Itself
        Without redundancy
     */
    function clone() external returns(address) {
        return _clone(address(this));
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function _clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }
}

interface DappdGeneratedNFT {
    function clone() external returns (address);
    function __init__(
        string calldata name,
        string calldata symbol,
        string calldata imageURI,
        uint256 maxSupply,
        address mintToken,
        uint256 cost,
        address owner
    ) external;
}

/**
    Generates NFT Smart Contracts For Users
    Created by DeFi Mark and dappd.net

    visit https://dappd.net to learn more!
 */
 contract DappdNFTGenerator is Ownable {

    // List Of All Proxies Generated By This Generator
    address[] public allGeneratedNFTs;
    address[] public allStandardNFTs;
    address[] public allLockedNFTs;
    address[] public allStakingNFTs;
    address[] public allArbitraryNFTs;
    address[] public allNFTsWithMintingPage;
    
    // mapping from users to user created NFTs
    mapping ( address => address[] ) public userCreatedNFTs;

    // Master Proxy Implementation Contract
    DappdGeneratedNFT private standardProxy;
    DappdGeneratedNFT private lockedProxy;
    DappdGeneratedNFT private stakingProxy;

    // Costs
    uint256 public standardCost;
    uint256 public lockedCost;
    uint256 public stakingCost;
    uint256 public arbitraryCost;
    uint256 public mintPageCost;

    // Fee Recipient
    address private feeReceiver;

    // Minting Page Add On
    mapping ( address => bool ) public hasMintingPage;

    // Mint Page Events
    event AddedMintPage(address NFT);
    event CreatedStandard(address NFTAddress);
    event CreatedLockedNFT(address NFTAddress);
    event CreatedStakingNFT(address NFTAddress);
    event CreatedArbitraryNFT(address ArbitraryAddress);

    constructor(
        address standardProxy_,
        address feeReceiver_,
        uint256 lockedCost_,
        uint256 stakingCost_,
        uint256 arbitraryCost_,
        uint256 mintPageCost_
    ) {
        standardProxy = DappdGeneratedNFT(payable(standardProxy_));
        feeReceiver = feeReceiver_;
        lockedCost = lockedCost_;
        stakingCost = stakingCost_;
        arbitraryCost = arbitraryCost_;
        mintPageCost = mintPageCost_;
    }

    function createStandardNFT(
        string calldata name,
        string calldata symbol,
        string calldata imageURI,
        uint256 maxSupply,
        address mintToken,
        uint256 cost,
        bool withMintPage
    ) external payable returns (address newNFT) {
        require(
            msg.value >= getCost(0, withMintPage),
            'Invalid Value Sent'
        );

        // creates new NFT Proxy
        newNFT = standardProxy.clone();

        // Initialize Proxy
        DappdGeneratedNFT(payable(newNFT)).__init__(
            name,
            symbol,
            imageURI,
            maxSupply,
            mintToken,
            cost,
            msg.sender
        );

        // Add To List Of Proxies
        allGeneratedNFTs.push(newNFT);
        allStandardNFTs.push(newNFT);
        userCreatedNFTs[msg.sender].push(newNFT);

        // list mint page
        if (withMintPage) {
            _addMintPage(newNFT);
        }

        // Emit Proxy Creation Event
        emit CreatedStandard(newNFT);
        _send();
    }

    function createLockedNFT(
        string calldata name,
        string calldata symbol,
        string calldata imageURI,
        uint256 maxSupply,
        address mintToken,
        uint256 cost,
        bool withMintPage
    ) external payable returns (address newNFT) {
        require(
            msg.value >= getCost(1, withMintPage),
            'Invalid Value Sent'
        );

        // creates new NFT Proxy
        newNFT = lockedProxy.clone();

        // Initialize Proxy
        DappdGeneratedNFT(payable(newNFT)).__init__(
            name,
            symbol,
            imageURI,
            maxSupply,
            mintToken,
            cost,
            msg.sender
        );

        // Add To List Of Proxies
        allGeneratedNFTs.push(newNFT);
        allLockedNFTs.push(newNFT);
        userCreatedNFTs[msg.sender].push(newNFT);

        // list mint page
        if (withMintPage) {
            _addMintPage(newNFT);
        }

        // Emit Proxy Creation Event
        emit CreatedLockedNFT(newNFT);
        _send();
    }

    function createStakingNFT(
        string calldata name,
        string calldata symbol,
        string calldata imageURI,
        uint256 maxSupply,
        address mintToken,
        uint256 cost,
        bool withMintPage
    ) external payable returns (address newNFT) {
        require(
            msg.value >= getCost(2, withMintPage),
            'Invalid Value Sent'
        );

        // creates new NFT Proxy
        newNFT = stakingProxy.clone();

        // Initialize Proxy
        DappdGeneratedNFT(payable(newNFT)).__init__(
            name,
            symbol,
            imageURI,
            maxSupply,
            mintToken,
            cost,
            msg.sender
        );

        // Add To List Of Proxies
        allGeneratedNFTs.push(newNFT);
        allStakingNFTs.push(newNFT);
        userCreatedNFTs[msg.sender].push(newNFT);

        // list mint page
        if (withMintPage) {
            _addMintPage(newNFT);
        }

        // Emit Proxy Creation Event
        emit CreatedStakingNFT(newNFT);
        _send();
    }

    function createArbitraryNFT(
        address arbitraryProxy,
        string calldata name,
        string calldata symbol,
        string calldata imageURI,
        uint256 maxSupply,
        address mintToken,
        uint256 cost,
        bool withMintPage
    ) external payable returns (address newNFT) {
        require(
            msg.value >= getCost(3, withMintPage),
            'Invalid Value Sent'
        );

        // creates new NFT Proxy
        newNFT = DappdGeneratedNFT(arbitraryProxy).clone();

        // Initialize Proxy
        DappdGeneratedNFT(payable(newNFT)).__init__(
            name,
            symbol,
            imageURI,
            maxSupply,
            mintToken,
            cost,
            msg.sender
        );

        // Add To List Of Arbitrary Proxies
        allArbitraryNFTs.push(newNFT);
        userCreatedNFTs[msg.sender].push(newNFT);

        // list mint page
        if (withMintPage) {
            _addMintPage(newNFT);
        }

        // Emit Proxy Creation Event
        emit CreatedArbitraryNFT(newNFT);
        _send();
    }

    function withdraw() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function withdrawToken(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function setStandardProxy(address proxy) external onlyOwner {
        standardProxy = DappdGeneratedNFT(payable(proxy));
    }

    function setLockedProxy(address proxy) external onlyOwner {
        lockedProxy = DappdGeneratedNFT(payable(proxy));
    }

    function setStakingProxy(address proxy) external onlyOwner {
        stakingProxy = DappdGeneratedNFT(payable(proxy));
    }

    function setLockedCost(uint256 newCost) external onlyOwner {
        lockedCost = newCost;
    }

    function setStakingCost(uint256 newCost) external onlyOwner {
        stakingCost = newCost;
    }

    function setStandardCost(uint256 newCost) external onlyOwner {
        standardCost = newCost;
    }

    function setArbitraryCost(uint256 newCost) external onlyOwner {
        arbitraryCost = newCost;
    }

    function setMintPageCost(uint256 newCost) external onlyOwner {
        mintPageCost = newCost;
    }

    function setFeeReceiver(address newReceiver) external onlyOwner {
        feeReceiver = newReceiver;
    }

    function addMintPage(address nft) external payable {
        require(
            msg.value >= mintPageCost,
            'Invalid Value Sent'
        );
        _addMintPage(nft);
    }

    function viewAllGeneratedNFTs() external view returns (address[] memory) {
        return allGeneratedNFTs;
    }
    function viewAllStandardNFTs() external view returns (address[] memory) {
        return allStandardNFTs;
    }
    function viewAllLockedNFTs() external view returns (address[] memory) {
        return allLockedNFTs;
    }
    function viewAllStakingNFTs() external view returns (address[] memory) {
        return allStakingNFTs;
    }
    function viewAllArbitraryNFTs() external view returns (address[] memory) {
        return allArbitraryNFTs;
    }
    function viewAllNFTsWithMintingPage() external view returns (address[] memory) {
        return allNFTsWithMintingPage;
    }
    function viewAllUserCreatedNFTs(address user) external view returns (address[] memory) {
        return userCreatedNFTs[user];
    }

    function getCost(uint8 tier, bool withMintPage) public view returns (uint256) {
        if (tier == 0) {
            return withMintPage ? standardCost + mintPageCost : standardCost;
        } else if (tier == 1) {
            return withMintPage ? lockedCost + mintPageCost : lockedCost;
        } else if (tier == 2) {
            return withMintPage ? stakingCost + mintPageCost : stakingCost;
        } else if (tier == 3) {
            return withMintPage ? arbitraryCost + mintPageCost : arbitraryCost;
        } else {
            return standardCost + lockedCost + stakingCost + arbitraryCost + mintPageCost;
        }
    }

    function getCosts() external view returns (uint256 standard, uint256 locked, uint256 staked, uint256 arbitrary, uint256 mintPage) {
        standard = standardCost;
        locked = lockedCost;
        staked = stakingCost;
        arbitrary = arbitraryCost;
        mintPage = mintPageCost;
    }

    function _send() internal {
        if (address(this).balance > 0 && feeReceiver != address(0)) {
            (bool s,) = payable(feeReceiver).call{value: address(this).balance}("");
            require(s);
        }
    }

    function _addMintPage(address nft) internal {
        hasMintingPage[nft] = true;
        allNFTsWithMintingPage.push(nft);
        emit AddedMintPage(nft);
    }
}
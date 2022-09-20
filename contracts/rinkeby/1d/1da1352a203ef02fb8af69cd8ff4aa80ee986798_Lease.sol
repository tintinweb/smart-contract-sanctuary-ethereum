// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/Manageable.sol";
import "./lib/Ecrecovery.sol";
import "./lib/CapitalPool.sol";
import "./lib/Lease.sol";
import "./interfaces/CapitalPoolInterface.sol";
import "./interfaces/LeaseInterface.sol";
import "./interfaces/FTInterface.sol";
import "./interfaces/NFTInterface.sol";


/**
 * @title LeaseSetup.sol
 * @author lixin
 * @notice LeaseSetup.sol set up lease module
 */
contract LeaseSetUp {

    event SetUp(address capitalPool, address lease);

    constructor(){
        CapitalPool capitalPool = new CapitalPool();
        Lease lease = new Lease(address(capitalPool));
        capitalPool.setLease(address(lease));

        emit SetUp(address(capitalPool), address(lease));

        selfdestruct(payable(msg.sender));
    }
}

contract LeaseSetUpWithManager {

    event SetUp(address capitalPool, address lease);

    constructor(address manager){
        CapitalPool capitalPool = new CapitalPool();
        Lease lease = new Lease(address(capitalPool));
        capitalPool.setLease(address(lease));

        capitalPool.transferManagership(manager);
        lease.transferManagership(manager);

        emit SetUp(address(capitalPool), address(lease));

        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface NFTInterface {
    function checkPrice(uint256 tokenId) external view returns (address tokenAddr, uint256 tokenAmount);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface FTInterface {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../lib/LeaseStructs.sol";
/**
 * @title LeaseInterface
 * @author lixin
 * @notice LeaseInterface contains all external function interfaces, events,
 *         and errors for LeaseSetup.sol contracts.
 */

interface LeaseInterface is LeaseStructs {

    event Lease(string businessId, address NFTAddr, uint256 NFTId, address FTAddr, uint256 term);

    event InjectFT(string businessId, address[] FTAddrs, uint256[] FTAmounts);

    event Settlement(string businessId, address[] FTAddrs, uint256[] FTAmounts);

    event WithdrawFT(string[] businessIds, address[] FTAddrs, uint256[] FTAmounts, address operator);

    event WithdrawNFT(string[] businessIds, address[] NFTAddrs, uint256[] NFTIds, address[] FTAddrs, uint256[] FTAmounts, address operator);

    event WithdrawNFTManager(string[] businessIds, address[] NFTAddrs, uint256[] NFTIds, address operator);

    event LeaseCapitalPoolChanged(address oldCapitalPool, address newCapitalPool);

    error NFTTransferFailed();

    error ArrayLengthMismatch();

    error NOTChangePenalty();

    error IllegalManagerSign();

    error NOTYOURNFT();

    error NOTExpired();

    /**
     * @notice User lease a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param NFTAddr Leased NFT contract address
     * @param NFTId NFT Id of the lease
     * @param FTAddr Fungible Token to lease
     * @param creationTimestamp  lease creation timestamp in seconds
     * @param term Rental term in seconds
     * @param managerSign manager Sign
     */
    function lease(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        address FTAddr,
        uint256 creationTimestamp,
        uint256 term,
        bytes calldata managerSign
    ) external returns (bool);

    /**
     * @notice Fungible Token injection by the platform.
     *
     * @param businessId Used as business differentiation.
     * @param FTAddrs Fungible Tokens to capital pool.
     * @param FTAmounts Fungible Tokens amount to inject to capital pool
     */
    function injectFT(
        string calldata businessId,
        address[] calldata FTAddrs,
        uint256[] calldata FTAmounts
    ) external returns (bool);

    /**
     * @notice Settle the rent of a month.
     *
     * @param businessId Used as business differentiation.
     * @param FTAddrs Fungible Tokens to settlement.
     * @param FTAmounts Fungible Tokens amount to settlement.
     */
    function settlement(
        string calldata businessId,
        address[] calldata FTAddrs,
        uint256[] calldata FTAmounts
    ) external returns (bool);

    /**
     * @notice User withdraws rent.
     *
     * @param businessIds Used as business differentiation.
     * @param FTAddrs Rent Fungible Tokens to be collected
     * @param FTAmounts Rent Fungible Tokens amount to be collected
     * @param managerSign Fungible Tokens amount to settlement.
     * @param managerSign Manager's signature on and call parameters.
     */
    function withdrawFT(
        string[] calldata businessIds,
        address[] calldata FTAddrs,
        uint256[] calldata FTAmounts,
        bytes calldata managerSign
    ) external returns (bool);

    /**
     * @notice Manager withdraws rent.
     *
     * @param businessIds Used as business differentiation.
     * @param FTAddrs Rent Fungible Tokens to be collected
     * @param FTAmounts Rent Fungible Tokens amount to be collected
     */
    function withdrawFTManager(
        string[] calldata businessIds,
        address[] calldata FTAddrs,
        uint256[] calldata FTAmounts
    ) external returns (bool);

    /**
     * @notice User withdraws rent.
     *
     * @param businessIds Used as business differentiation.
     * @param NFTAddrs Leased NFTs contract address.
     * @param NFTIds NFTs Id leased.
     * @param FTAddrs Rent Fungible Tokens to be collected
     * @param FTAmounts Rent Fungible Tokens amount to be collected
     * @param managerSign Manager's signature on and call parameters.
     */
    function withdrawNFT(
        string[] calldata businessIds,
        address[]  calldata NFTAddrs,
        uint256[]  calldata NFTIds,
        address[]  calldata FTAddrs,
        uint256[]  calldata FTAmounts,
        bytes calldata managerSign
    ) external returns (bool);

    /**
     * @notice User withdraws rent.
     *
     * @param businessIds Used as business differentiation.
     * @param NFTAddrs Leased NFTs contract address.
     * @param NFTIds NFTs Id leased.
     */
    function withdrawNFTManager(
        string[] calldata businessIds,
        address[]  calldata NFTAddrs,
        uint256[]  calldata NFTIds
    ) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./IERC721Receiver.sol";

/**
 * @title CapitalPoolInterface
 * @author lixin
 * @notice CapitalPoolInterface contains all external function interfaces, events,
 *         and errors for CapitalPool contracts.
 */

interface CapitalPoolInterface is IERC721Receiver {

    /**
     * @dev Emit an event when receive a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    event ReceiveFT(string businessId, address tokenAddr, uint256 tokenAmount);

    event FrozenFT(string businessId, address tokenAddr, uint256 tokenAmount);

    /**
     * @dev Emit an event when Withdraw a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    event WithdrawFT(string businessId, address tokenAddr, uint256 tokenAmount, address recipient);

    /**
     * @dev Emit an event when receive a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     */
    event ReceiveNFT(string businessId, address tokenAddr, uint256 tokenId);

    /**
     * @dev Emit an event when Withdraw a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     */
    event WithdrawNFT(string businessId, address tokenAddr, uint256 tokenId, address recipient);

    event LeaseChanged(address oldLease, address newLease);

    error NoFTReceived();
    
    error NotEnoughFT();

    error BusinessIdUsed();

    /**
     * @dev Revert with an error when run failed.
     */
    error failed();

    /**
     * @notice receive a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function depositFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount
    )external returns (bool);

    function frozenFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount
    ) external returns (bool);

    /**
     * @notice Only loan contract can withdraw a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function withdrawFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount,
        address receipt
    )external returns (bool);

    /**
     * @notice Only manager can withdraw a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function withdrawFTManager(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount,
        address receipt
    )external returns (bool);


    /**
     * @notice Only pledge can withdraw a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     */
    function withdrawNFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenId,
        address receipt
    )external returns (bool);

     /**
     * @notice Only manager can withdraw a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function withdrawNFTManager(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount,
        address receipt
    )external returns (bool);

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Manageable.sol";
import "./Ecrecovery.sol";
import "./CapitalPool.sol";
import "../interfaces/CapitalPoolInterface.sol";
import "../interfaces/LeaseInterface.sol";
import "../interfaces/FTInterface.sol";
import "../interfaces/NFTInterface.sol";
import "./ReentrancyGuard.sol";


/**
 * @title Lease
 * @author lixin
 * @notice Lease Process all modules of the lease
 */
contract Lease is LeaseInterface, Manageable, ReentrancyGuard {

    address public leaseCapitalPool;
    // NFTAddr => NFTId => LeaseList
    mapping(address => mapping(uint256 => LeaseList)) public leaseLists;

    constructor(address newLeaseCapitalPool){
        setLeaseCapitalPool(newLeaseCapitalPool);
    }

    function setLeaseCapitalPool(
        address newLeaseCapitalPool
    ) public onlyManager {
        address oldLeaseCapitalPool = leaseCapitalPool;
        leaseCapitalPool = newLeaseCapitalPool;
        emit LeaseCapitalPoolChanged(oldLeaseCapitalPool, newLeaseCapitalPool);
    }

    /**
     * @notice User lease a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param NFTAddr Leased NFT contract address
     * @param NFTId NFT Id of the lease
     * @param FTAddr Fungible Token to lease
     * @param creationTimestamp  lease creation timestamp in seconds
     * @param term Rental term in seconds
     * @param managerSign manager Sign
     */
    function lease(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        address FTAddr,
        uint256 creationTimestamp,
        uint256 term,
        bytes calldata managerSign
    ) external nonReentrant returns (bool){
        require(verify(businessId, NFTAddr, NFTId, FTAddr, creationTimestamp, term, managerSign));

        NFTInterface(NFTAddr).safeTransferFrom(_msgSender(), leaseCapitalPool, NFTId, bytes(businessId));
        if (NFTInterface(NFTAddr).ownerOf(NFTId) != leaseCapitalPool) {
            revert NFTTransferFailed();
        }

        LeaseList storage leaseList = leaseLists[NFTAddr][NFTId];
        leaseList.leaser = _msgSender();
        leaseList.NFTAddr = NFTAddr;
        leaseList.NFTId = NFTId;
        leaseList.FTAddr = FTAddr;
        leaseList.creationTimestamp = creationTimestamp;
        leaseList.term = term;

        emit Lease(businessId, NFTAddr, NFTId, FTAddr, term);

        return true;
    }

    function verify(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        address FTAddr,
        uint256 creationTimestamp,
        uint256 term,
        bytes calldata managerSign
    ) internal view returns (bool){
        bytes32 hash = keccak256(abi.encode(businessId, NFTAddr, NFTId, FTAddr, creationTimestamp, term, _msgSender()));
        if (Ecrecovery.ecrecovery(hash, managerSign) != manager()) {
            revert IllegalManagerSign();
        }
        return true;
    }

    /**
     * @notice Fungible Token injection by the platform.
     *
     * @param businessId Used as business differentiation.
     * @param FTAddrs Fungible Tokens to capital pool.
     * @param FTAmounts Fungible Tokens amount to inject to capital pool
     */
    function injectFT(
        string calldata businessId,
        address[] calldata FTAddrs,
        uint256[] calldata FTAmounts
    ) external nonReentrant returns (bool){
        uint256 len = FTAddrs.length;
        if (len != FTAmounts.length) {
            revert ArrayLengthMismatch();
        }

        for (uint i = 0; i < len; ++i) {
            require(FTInterface(FTAddrs[i]).transferFrom(_msgSender(), leaseCapitalPool, FTAmounts[i]), "FT transfer failed");
            CapitalPoolInterface(leaseCapitalPool).depositFT(businessId, FTAddrs[i], FTAmounts[i]);
        }
        emit InjectFT(businessId, FTAddrs, FTAmounts);
        return true;
    }

    /**
    * @notice Settle the rent of a month. Only manager can call this function.
     *
     * @param businessId Used as business differentiation.
     * @param FTAddrs Fungible Tokens to settlement.
     * @param FTAmounts Fungible Tokens amount to settlement.
     */
    function settlement(
        string calldata businessId,
        address[] calldata FTAddrs,
        uint256[] calldata FTAmounts
    ) external onlyManager nonReentrant returns (bool){
        uint256 len = FTAddrs.length;
        if (len != FTAmounts.length) {
            revert ArrayLengthMismatch();
        }

        for (uint i = 0; i < len; ++i) {
            CapitalPoolInterface(leaseCapitalPool).frozenFT(businessId, FTAddrs[i], FTAmounts[i]);
        }
        emit Settlement(businessId, FTAddrs, FTAmounts);
        return true;
    }

    /**
     * @notice User withdraws rent.
     *
     * @param businessIds Used as business differentiation.
     * @param FTAddrs Rent Fungible Tokens to be collected
     * @param FTAmounts Rent Fungible Tokens amount to be collected
     * @param managerSign Manager's signature on and call parameters.
     */
    function withdrawFT(
        string[] calldata businessIds,
        address[] calldata FTAddrs,
        uint256[] calldata FTAmounts,
        bytes calldata managerSign
    ) external nonReentrant returns (bool){

        require(verify(businessIds, FTAddrs, FTAmounts, managerSign));

        uint256 len = FTAddrs.length;
        if (len != FTAmounts.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < len; ++i) {

            require(_withdrawFT(businessIds[i], FTAddrs[i], FTAmounts[i]));
        }

        emit WithdrawFT(businessIds, FTAddrs, FTAmounts, _msgSender());
        return true;
    }

    function verify(
        string[] calldata businessIds,
        address[]  calldata FTAddrs,
        uint256[]  calldata FTAmounts,
        bytes calldata managerSign
    ) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encode(businessIds, FTAddrs, FTAmounts, _msgSender()));
        if (Ecrecovery.ecrecovery(hash, managerSign) != manager()) {
            revert IllegalManagerSign();
        }
        return true;
    }

    function _withdrawFT(
        string calldata businessId,
        address FTAddr,
        uint256 FTAmount
    ) internal returns (bool){
        require(CapitalPoolInterface(leaseCapitalPool).withdrawFT(businessId, FTAddr, FTAmount, _msgSender()));
        return true;
    }

    /**
     * @notice Manager withdraws rent. Only manager can call this function.
     *
     * @param businessIds Used as business differentiation.
     * @param FTAddrs Rent Fungible Tokens to be collected
     * @param FTAmounts Rent Fungible Tokens amount to be collected
     */
    function withdrawFTManager(
        string[] calldata businessIds,
        address[] calldata FTAddrs,
        uint256[] calldata FTAmounts
    ) external onlyManager nonReentrant returns (bool) {
        uint256 len = FTAddrs.length;
        if (len != FTAmounts.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < len; ++i) {
            require(_withdrawFT(businessIds[i], FTAddrs[i], FTAmounts[i]));
        }

        emit WithdrawFT(businessIds, FTAddrs, FTAmounts, _msgSender());

        return true;
    }

    /**
     * @notice User withdraws NFT.
     *
     * @param businessIds Used as business differentiation.
     * @param NFTAddrs Leased NFTs contract address.
     * @param NFTIds NFTs Id leased.
     * @param managerSign Manager's signature on and call parameters.
     */
    function withdrawNFT(
        string[] calldata businessIds,
        address[]  calldata NFTAddrs,
        uint256[]  calldata NFTIds,
        address[]  calldata FTAddrs,
        uint256[]  calldata FTAmounts,
        bytes calldata managerSign
    ) external nonReentrant returns (bool){
        require(verify(businessIds, NFTAddrs, NFTIds, FTAddrs, FTAmounts, managerSign));

        uint256 len = NFTAddrs.length;
        if (len != NFTIds.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < len; ++i) {
            require(_withdrawNFT(businessIds[i], NFTAddrs[i], NFTIds[i], FTAddrs[i], FTAmounts[i]));
        }

        emit WithdrawNFT(businessIds, NFTAddrs, NFTIds, FTAddrs, FTAmounts, _msgSender());

        return true;

    }

    function verify(
        string[] calldata businessId,
        address[]  calldata NFTAddrs,
        uint256[]  calldata NFTIds,
        address[]  calldata FTAddrs,
        uint256[]  calldata FTAmounts,
        bytes calldata managerSign
    ) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encode(businessId, NFTAddrs, NFTIds, FTAddrs, FTAmounts, _msgSender()));
        if (Ecrecovery.ecrecovery(hash, managerSign) != manager()) {
            revert IllegalManagerSign();
        }
        return true;
    }


    function _withdrawNFT(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        address FTAddr,
        uint256 FTAmount
    ) internal returns (bool){
        LeaseList storage leaseList = leaseLists[NFTAddr][NFTId];

        if (leaseList.leaser != _msgSender()) {
            revert NOTYOURNFT();
        }

        if (leaseList.creationTimestamp + leaseList.term <= block.timestamp) {// 正常到期
            if (FTAmount != 0) {
                revert NOTChangePenalty();
            }
        } else {// 提前解除
            require(FTInterface(FTAddr).transferFrom(_msgSender(), leaseCapitalPool, FTAmount), "FT transfer failed");
        }
        require(CapitalPoolInterface(leaseCapitalPool).withdrawNFT(businessId, NFTAddr, NFTId, _msgSender()));

        return true;
    }

    function withdrawNFTManager(
        string[] calldata businessIds,
        address[]  calldata NFTAddrs,
        uint256[]  calldata NFTIds
    ) external onlyManager nonReentrant returns (bool){

        uint256 len = NFTAddrs.length;
        if (len != NFTIds.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < len; ++i) {
            LeaseList storage leaseList = leaseLists[NFTAddrs[i]][NFTIds[i]];
            if (leaseList.creationTimestamp + leaseList.term < block.timestamp) {
                require(CapitalPoolInterface(leaseCapitalPool).withdrawNFT(businessIds[i], NFTAddrs[i], NFTIds[i], leaseList.leaser));
            } else {
                revert NOTExpired();
            }
        }

        emit WithdrawNFTManager(businessIds, NFTAddrs, NFTIds, _msgSender());

        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../interfaces/CapitalPoolInterface.sol";
import "../interfaces/FTInterface.sol";
import "../interfaces/NFTInterface.sol";
import "./Manageable.sol";
import "./ReentrancyGuard.sol";

/**
 * @title CapitalPool
 * @author lixin
 * @notice CapitalPool Handle reception and transfer of NFT and FT.
 */

contract CapitalPool is CapitalPoolInterface, Manageable, ReentrancyGuard {

    //the lease contract address
    address public lease;

    //Freeze Fungible Token amount
    mapping(address => uint256) public frozen;

    mapping(address => uint256) public balanceOf;

    mapping(string => bool) businessBook;


    /**
     * @dev Throws if called by any account other than the lease.
     */
    modifier onlyLease() {
        require(lease != address(0), "Lease contract not ready");
        require(msg.sender == lease, "caller not the lease contract");
        _;
    }

    constructor(){}

    function setLease(
        address newLease
    ) public onlyManager {
        address oldLease = lease;
        lease = newLease;
        emit LeaseChanged(oldLease, newLease);
    }

    /**
     * @notice receive a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function depositFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount
    ) external nonReentrant returns (bool){
        if(businessBook[businessId]){
            revert BusinessIdUsed();
        }
        uint256 oldBalance = balanceOf[tokenAddr];
        uint256 newBalance = FTInterface(tokenAddr).balanceOf(address(this));
        if (oldBalance + tokenAmount > newBalance) {
            revert NoFTReceived();
        }
        balanceOf[tokenAddr] = newBalance;
        emit ReceiveFT(businessId, tokenAddr, tokenAmount);
        return true;
    }

    function frozenFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount
    ) external onlyManager onlyLease nonReentrant returns (bool){
        if(businessBook[businessId]){
            revert BusinessIdUsed();
        }
        uint256 balance = FTInterface(tokenAddr).balanceOf(address(this));
        uint256 frozenAmount = frozen[tokenAddr];
        if (frozenAmount + tokenAmount > balance) {
            revert NotEnoughFT();
        }
        frozen[tokenAddr] += tokenAmount;
        balanceOf[tokenAddr] = balance;
        emit FrozenFT(businessId, tokenAddr, tokenAmount);
        return true;
    }


    /**
     * @notice Only loan contract can withdraw a FT.Only the loan contract can call this function.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function withdrawFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount,
        address recipient
    ) external onlyLease nonReentrant returns (bool){
        if(businessBook[businessId]){
            revert BusinessIdUsed();
        }
        uint256 frozenAmount = frozen[tokenAddr];
        if (frozenAmount < tokenAmount) {
            revert NotEnoughFT();
        }
        require(FTInterface(tokenAddr).transfer(recipient, tokenAmount), "FT transfer failed");
        emit WithdrawFT(businessId, tokenAddr, tokenAmount, recipient);
        return true;
    }

    /**
     * @notice Only pledge can withdraw a NFT. Only the pledge contract can call this function.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     */
    function withdrawNFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenId,
        address recipient
    ) external onlyLease nonReentrant returns (bool){
        if(businessBook[businessId]){
            revert BusinessIdUsed();
        }
        NFTInterface(tokenAddr).safeTransferFrom(address(this), recipient, tokenId, "0x");
        emit WithdrawNFT(businessId, tokenAddr, tokenId, recipient);
        return true;
    }

    /**
    * @notice Only manager can withdraw a FT. Only the manager can call this function.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function withdrawFTManager(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount,
        address recipient
    ) external onlyLease onlyManager nonReentrant returns (bool){
        if(businessBook[businessId]){
            revert BusinessIdUsed();
        }
        uint256 frozenAmount = frozen[tokenAddr];
        uint256 balance = FTInterface(tokenAddr).balanceOf(address(this));
        if (balance - frozenAmount < tokenAmount) {
            revert NotEnoughFT();
        }
        FTInterface(tokenAddr).transfer(recipient, tokenAmount);
        emit WithdrawFT(businessId, tokenAddr, tokenAmount, recipient);
        return true;
    }

    /**
    * @notice Only manager can withdraw a FT. Only the manager can call this function.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenId The amount of ERC20 tokens.
     */
    function withdrawNFTManager(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenId,
        address recipient
    ) external onlyLease onlyManager nonReentrant returns (bool){
        if(businessBook[businessId]){
            revert BusinessIdUsed();
        }
        NFTInterface(tokenAddr).safeTransferFrom(address(this), recipient, tokenId, "0x");
        emit WithdrawNFT(businessId, tokenAddr, tokenId, recipient);
        return true;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     */
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        if(businessBook[string(data)]){
            revert BusinessIdUsed();
        }
        emit ReceiveNFT(string(data), _msgSender(), tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Ecrecovery{

function ecrecovery(
        bytes32 hash,
        bytes memory sig
    )
    internal
    pure
    returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        /* prefix might be needed for geth only
        * https://github.com/ethereum/go-ethereum/issues/3731
        */
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        bytes32 Hash = keccak256(abi.encodePacked(prefix, hash));

        return ecrecover(Hash, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Manageable is Ownable {
    address private _manager;

    event ManagershipTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    constructor() {
        _transferManagership(_txOrigin());
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        _checkManager();
        _;
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if the sender is not the manager.
     */
    function _checkManager() internal view virtual {
        require(manager() == _txOrigin(), "Managerable: caller is not the manager");
    }

    /**
     * @dev Transfers managership of the contract to a new account (`newManager`).
     * Can only be called by the current owner.
     */
    function transferManagership(address newManager) public virtual onlyOwner {
        require(newManager != address(0), "Managerable: new manager is the zero address");
        _transferManagership(newManager);
    }

    /**
     * @dev Transfers Managership of the contract to a new account (`newManager`).
     * Internal function without access restriction.
     */
    function _transferManagership(address newManager) internal virtual {
        address oldManager = _manager;
        _manager = newManager;
        emit ManagershipTransferred(oldManager, newManager);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _transferOwnership(_txOrigin());
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
        require(owner() == _txOrigin(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    error ReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        //require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        if(_status == _ENTERED){
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title LeaseStructs
 * @author lixin
 * @notice LeaseStructs contains all structs for LeaseSetup.sol contracts.
 */

 interface LeaseStructs {
        
        struct LeaseList{
            address leaser;// leaser
            address NFTAddr;// Leased NFT contract address
            uint256 NFTId;// Leased NFT Id
            address FTAddr;// Fungible Token address to rent
            uint256 creationTimestamp;
            uint256 term;// Rental term in seconds
        }

        struct List{
            address FTAddr;// Fungible Token address to rent
            uint256 creationTimestamp;
            uint256 term;// Rental term in seconds
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

}
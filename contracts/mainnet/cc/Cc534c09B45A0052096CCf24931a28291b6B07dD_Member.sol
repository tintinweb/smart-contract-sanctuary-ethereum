//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/TokenActions.sol";
import "./libraries/Errors.sol";
import "./interfaces/IProtocolDirectory.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IMembership.sol";
import "./interfaces/IAssetStore.sol";
import "./interfaces/IAssetStoreFactory.sol";
import "./structs/MemberStruct.sol";
import "./structs/TokenStruct.sol";
import "./structs/ApprovalsStruct.sol";

//

/**
 * @title AssetsStore
 * @notice This contract is deployed by the AssetsStoreFactory.sol
 * and is the contract that holds the approvals for a user's directives
 *
 * @dev The ownership of this contract is held by the deployer factory
 *
 */

contract AssetsStore is IAssetStore, Ownable, ReentrancyGuard {
    // Returns token Approvals for specific UID
    mapping(string => Approvals[]) private MemberApprovals;

    // Mapping Beneficiaries to a specific Approval for Claiming
    mapping(address => Approvals[]) private BeneficiaryClaimableAsset;

    // Storing ApprovalId for different approvals stored
    uint256 private _approvalsId;

    // address for the protocol directory contract
    address private directoryContract;

    address private IMembershipAddress;

    /**
     * @notice Event used for querying approvals stored
     * by this contract
     *
     * @param uid string of the central identifier within the dApp
     * @param approvedWallet address for original holder of the asset
     * @param beneficiaryName string associated with beneficiaryAddress wallet
     * @param beneficiaryAddress address for the wallet receiving the assets
     * @param tokenId uint256 of the ID of the token being transferred
     * @param tokenAddress address for the contract of the asset
     * @param tokenType string representing what ERC the token is
     * @param tokensAllocated uint256 representing the % allocation of an asset
     * @param dateApproved uint256 for the block number when the approval is acted on
     * @param claimed bool for showing if the approval has been claimed by a beneficiary
     * @param active bool for if the claiming period is currently active
     * @param approvalId uint256 representing which approval the event is tied to
     * @param claimExpiryTime uint256 of a block number when claiming can no longer happen
     * @param approvedTokenAmount uint256 representing the magnitude of tokens to be transferred
     * at the time of claiming.
     *
     */
    event ApprovalsEvent(
        string uid,
        address approvedWallet,
        string beneficiaryName,
        address beneficiaryAddress,
        uint256 tokenId,
        address tokenAddress,
        string tokenType,
        uint256 tokensAllocated,
        uint256 dateApproved,
        bool claimed,
        bool active,
        uint256 approvalId,
        uint256 claimExpiryTime,
        uint256 approvedTokenAmount
    );

    /**
     * @dev Modifier to ensure that the user exists within the ecosystem
     * @param uid string of the central identifier used for this user within the dApp
     *
     */
    modifier checkIfMember(string memory uid) {
        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();
        if (bytes(IMember(IMemberAddress).getMember(uid).uid).length == 0) {
            revert(Errors.AS_USER_DNE);
        }
        _;
    }

    /**
     * @dev Modifier checking that only the RelayerContract can invoke certain functions
     *
     */
    modifier onlyRelayerContract() {
        address relayerAddress = IProtocolDirectory(directoryContract)
            .getRelayerContract();
        if (msg.sender != relayerAddress) {
            revert(Errors.AS_ONLY_RELAY);
        }
        _;
    }

    /**
     * @dev Modifier to ensure a function can only be invoked by
     * the ChainlinkOperationsContract
     */
    modifier onlyChainlinkOperationsContract() {
        address linkOpsAddress = IProtocolDirectory(directoryContract)
            .getChainlinkOperationsContract();
        if (msg.sender != linkOpsAddress) {
            revert(Errors.AS_ONLY_CHAINLINK_OPS);
        }
        _;
    }

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of the ProtocolDirectory Contract
     * @param _membershipAddress address of the Contract deployed for this
     * user's membership
     */
    constructor(address _directoryContract, address _membershipAddress) {
        directoryContract = _directoryContract;
        IMembershipAddress = _membershipAddress;
        _approvalsId = 0;
    }

    /**
     * @notice Function to store All Types of Approvals and Backups by the user in one function
     * @dev storeAssetsAndBackUpApprovals calls
     *  storeBackupAssetsApprovals & storeAssetsApprovals
     * 
     * sent to storeAssetsApprovals:
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     
     * sent to storeBackupAssetsApprovals:
     * @param _backUpTokenIds uint256[] Ordered list of tokenIds to be in a backup plan
     * @param _backupTokenAmount uint256[] Ordered list representing a magnitube of tokens to be in a backupPlan
     * @param _backUpWallets address[] Ordered list of destination wallets for the backupPlan
     * @param _backUpAddresses address[] Ordered list of contract addresses of assets for the backupPlan
     * @param _backupTokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param uid string of the dApp identifier for the user
     * 
     * 
     */
    function storeAssetsAndBackUpApprovals(
        address[] memory _contractAddress,
        address[] memory _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        string[] memory _tokenTypes,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenAmount,
        uint256[] memory _backUpTokenIds,
        uint256[] memory _backupTokenAmount,
        address[] memory _backUpWallets,
        address[] memory _backUpAddresses,
        string[] memory _backupTokenTypes,
        string memory uid
    ) external {
        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();
        if ((IMember(IMemberAddress).checkIfUIDExists(msg.sender) == false)) {
            IMember(IMemberAddress).createMember(uid, msg.sender);
        }
        checkUserHasMembership(uid);
        IMember(IMemberAddress).checkUIDofSender(uid, msg.sender);
        IMember(IMemberAddress).storeBackupAssetsApprovals(
            _backUpAddresses,
            _backUpTokenIds,
            _backUpWallets,
            _backupTokenAmount,
            _backupTokenTypes,
            uid,
            msg.sender,
            true
        );

        storeAssetsApprovals(
            _contractAddress,
            _tokenIds,
            _beneficiaries,
            _beneficiaryNames,
            _beneficiaryIsCharity,
            _tokenAmount,
            _tokenTypes,
            uid
        );
    }

    /**
     * @notice storeAssetsApprovals - Function to store All Types Approvals by the user
     * @dev All of the arrays passed in need to be IN ORDER
     * they will be accessed in a loop together
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _memberUID string of the dApp identifier for the user
     *
     */
    function storeAssetsApprovals(
        address[] memory _contractAddress,
        uint256[] memory _tokenIds,
        address[] memory _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        uint256[] memory _tokenAmount,
        string[] memory _tokenTypes,
        string memory _memberUID
    ) public {
        if (
            _tokenIds.length != _contractAddress.length ||
            _beneficiaryNames.length != _beneficiaries.length ||
            _tokenIds.length != _beneficiaries.length
        ) {
            revert(Errors.AS_DIFF_LENGTHS);
        }

        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();
        if ((IMember(IMemberAddress).checkIfUIDExists(msg.sender) == false)) {
            IMember(IMemberAddress).createMember(_memberUID, msg.sender);
        }
        checkUserHasMembership(_memberUID);

        member memory _member = IMember(IMemberAddress).getMember(_memberUID);
        if (
            msg.sender != IMember(IMemberAddress).getPrimaryWallet(_memberUID)
        ) {
            revert(Errors.AS_ONLY_PRIMARY_WALLET);
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address contractAddress = _contractAddress[i];
            uint256 tokenId_ = _tokenIds[i];
            address beneficiary_ = _beneficiaries[i];
            string memory beneficiaryName_ = _beneficiaryNames[i];
            string memory tokenType = _tokenTypes[i];
            bool isCharity = _beneficiaryIsCharity[i];
            uint256 tokenAmount = _tokenAmount[i];

            TokenActions.checkAssetContract(contractAddress, tokenType);
            if (tokenAmount > 100 || tokenAmount < 0) {
                revert(Errors.AS_INVALID_TOKEN_RANGE);
            }
            Beneficiary memory beneficiary = Beneficiary(
                beneficiary_,
                beneficiaryName_,
                isCharity
            );
            Token memory _token = Token(
                tokenId_,
                contractAddress,
                tokenType,
                tokenAmount
            );

            uint256 _dateApproved = block.timestamp;
            _storeAssets(
                _memberUID,
                _member,
                msg.sender,
                beneficiary,
                _token,
                _dateApproved
            );
            emit ApprovalsEvent(
                _member.uid,
                msg.sender,
                beneficiary.beneficiaryName,
                beneficiary.beneficiaryAddress,
                _token.tokenId,
                _token.tokenAddress,
                _token.tokenType,
                _token.tokensAllocated,
                _dateApproved,
                false,
                false,
                _approvalsId,
                0,
                0
            );
        }
        IMembership(IMembershipAddress).redeemUpdate(_memberUID);
    }

    /**
     * @dev _storeAssets - Internal function to store assets
     * @param uid string string of the dApp identifier for the user
     * @param _member member struct storing relevant data for the user
     * @param user address address of the user
     * @param _beneificiary Beneficiary struct storing data representing the beneficiary
     * @param _token Token struct containing information of the asset in the will
     * @param _dateApproved uint256 block timestamp when this function is called
     *
     */
    function _storeAssets(
        string memory uid,
        member memory _member,
        address user,
        Beneficiary memory _beneificiary,
        Token memory _token,
        uint256 _dateApproved
    ) internal {
        Approvals memory approval = Approvals(
            _member,
            user,
            _beneificiary,
            _token,
            _dateApproved,
            false,
            false,
            ++_approvalsId,
            0,
            0
        );

        BeneficiaryClaimableAsset[_beneificiary.beneficiaryAddress].push(
            approval
        );
        MemberApprovals[uid].push(approval);
    }

    /**
     * @notice getApproval - Function to get a specific token Approval for the user passing in UID and ApprovalID
     * @dev searches state for a match by uid and approvalId for a given user
     *
     * @param uid string of the dApp identifier for the user
     * @param approvalId number of the individual approval to lookup
     *
     * @return approval_ struct storing information for an Approval
     */
    function getApproval(string memory uid, uint256 approvalId)
        external
        view
        returns (Approvals memory approval_)
    {
        Approvals[] memory _approvals = MemberApprovals[uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            if (_approvals[i].approvalId == approvalId) {
                approval_ = _approvals[i];
            }
        }
    }

    /**
     * @notice getBeneficiaryApproval - Function to get a token Approval for the beneficiaries - Admin function
     * @param _benAddress address to lookup a specific list of approvals for given beneficiary address
     * @return approval_ a list of approval structs for a specific address
     */
    function getBeneficiaryApproval(address _benAddress)
        external
        view
        onlyOwner
        returns (Approvals[] memory approval_)
    {
        approval_ = BeneficiaryClaimableAsset[_benAddress];
    }

    /**
     * @notice getApprovals - Function to get all token Approvals for the user
     * @param uid string of the dApp identifier for the user
     * @return Approvals[] a list of all the approval structs associated with a user
     */
    function getApprovals(string memory uid)
        external
        view
        returns (Approvals[] memory)
    {
        return MemberApprovals[uid];
    }

    /**
     * @notice setApprovalClaimed - Function to set approval claimed for a specific apprival id
     * @param uid string of the dApp identifier for the user
     * @param _id uint256 the id of the approval claimed
     *
     * emits an event to indicate state change of an approval as well
     * as changing the state inside of the MemberApprovals list
     */
    function setApprovalClaimed(string memory uid, uint256 _id) internal {
        Approvals[] storage _approvals = MemberApprovals[uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            if (_approvals[i].approvalId == _id) {
                _approvals[i].claimed = true;
                _approvals[i].active = false;
                emit ApprovalsEvent(
                    _approvals[i].Member.uid,
                    _approvals[i].approvedWallet,
                    _approvals[i].beneficiary.beneficiaryName,
                    _approvals[i].beneficiary.beneficiaryAddress,
                    // _approvals[i].beneficiary.isCharity,
                    _approvals[i].token.tokenId,
                    _approvals[i].token.tokenAddress,
                    _approvals[i].token.tokenType,
                    _approvals[i].token.tokensAllocated,
                    _approvals[i].dateApproved,
                    _approvals[i].claimed,
                    _approvals[i].active,
                    _approvals[i].approvalId,
                    _approvals[i].claimExpiryTime,
                    _approvals[i].approvedTokenAmount
                );
            }
        }
    }

    /**
     * @dev setBenApprovalClaimed - Function to set approval claimed for a specific apprival id for ben
     * @param _user address of the dApp identifier for the user
     * @param _id uint256 the id of the approval claimed
     *
     * emits an event to indicate state change of an approval as well
     * as changing the state inside of the BeneficiaryClaimableAsset list
     */
    function setBenApprovalClaimed(address _user, uint256 _id) internal {
        Approvals[] storage _approvals = BeneficiaryClaimableAsset[_user];
        for (uint256 i = 0; i < _approvals.length; i++) {
            if (_approvals[i].approvalId == _id) {
                _approvals[i].claimed = true;
                _approvals[i].active = false;
                emit ApprovalsEvent(
                    _approvals[i].Member.uid,
                    _approvals[i].approvedWallet,
                    _approvals[i].beneficiary.beneficiaryName,
                    _approvals[i].beneficiary.beneficiaryAddress,
                    // _approvals[i].beneficiary.isCharity,
                    _approvals[i].token.tokenId,
                    _approvals[i].token.tokenAddress,
                    _approvals[i].token.tokenType,
                    _approvals[i].token.tokensAllocated,
                    _approvals[i].dateApproved,
                    _approvals[i].claimed,
                    _approvals[i].active,
                    _approvals[i].approvalId,
                    _approvals[i].claimExpiryTime,
                    _approvals[i].approvedTokenAmount
                );
            }
        }
    }

    /**
     * @notice transferUnclaimedAsset - Function to claim Unclaimed Assets passed the claimable expiry time
     * @param uid string of the dApp identifier for the user
     */
    function transferUnclaimedAssets(string memory uid)
        external
        onlyRelayerContract
        nonReentrant
    {
        address TransferPool = IProtocolDirectory(directoryContract)
            .getTransferPool();
        Approvals[] storage _approval = MemberApprovals[uid];
        for (uint256 i = 0; i < _approval.length; i++) {
            if (
                block.timestamp >= _approval[i].claimExpiryTime &&
                _approval[i].active == true &&
                _approval[i].claimed == false
            ) {
                if (
                    keccak256(
                        abi.encodePacked((_approval[i].token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC20")))
                ) {
                    IERC20 ERC20 = IERC20(_approval[i].token.tokenAddress);

                    // Percentage approach for storing erc20
                    uint256 _tokenAmount = (_approval[i].token.tokensAllocated *
                        ERC20.balanceOf(_approval[i].approvedWallet)) / 100;

                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(
                        _approval[i].beneficiary.beneficiaryAddress,
                        _approval[i].approvalId
                    );
                    bool sent = ERC20.transferFrom(
                        _approval[i].approvedWallet,
                        TransferPool,
                        _tokenAmount
                    );
                }

                // transfer erc721
                if (
                    keccak256(
                        abi.encodePacked((_approval[i].token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC721")))
                ) {
                    IERC721 ERC721 = IERC721(_approval[i].token.tokenAddress);

                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(
                        _approval[i].beneficiary.beneficiaryAddress,
                        _approval[i].approvalId
                    );
                    ERC721.safeTransferFrom(
                        _approval[i].approvedWallet,
                        TransferPool,
                        _approval[i].token.tokenId
                    );
                }

                // transfer erc1155
                if (
                    keccak256(
                        abi.encodePacked((_approval[i].token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC1155")))
                ) {
                    IERC1155 ERC1155 = IERC1155(
                        _approval[i].token.tokenAddress
                    );
                    uint256 _tokenAmount = (_approval[i].token.tokensAllocated *
                        ERC1155.balanceOf(
                            _approval[i].approvedWallet,
                            _approval[i].token.tokenId
                        )) / 100;

                    bytes memory data;
                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(
                        _approval[i].beneficiary.beneficiaryAddress,
                        _approval[i].approvalId
                    );
                    ERC1155.safeTransferFrom(
                        _approval[i].approvedWallet,
                        TransferPool,
                        _approval[i].token.tokenId,
                        _tokenAmount,
                        data
                    );
                }
            }
        }
    }

    /**
     * @dev claimAsset - Function to claim Asset from a specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId_ uint256 id of the specific approval being claimed
     * @param benUID string of the dApp identifier for the beneficiary claiming the asset
     *
     */
    function claimAsset(
        string memory uid,
        uint256 approvalId_,
        string memory benUID
    ) external nonReentrant {
        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();
        if ((IMember(IMemberAddress).checkIfUIDExists(msg.sender) == false)) {
            IMember(IMemberAddress).createMember(benUID, msg.sender);
        }
        Approvals[] storage _approval = BeneficiaryClaimableAsset[msg.sender];
        for (uint256 i = 0; i < _approval.length; i++) {
            if (
                keccak256(abi.encodePacked((_approval[i].Member.uid))) ==
                keccak256(abi.encodePacked((uid)))
            ) {
                if (_approval[i].beneficiary.beneficiaryAddress != msg.sender) {
                    revert(Errors.AS_ONLY_BENEFICIARY);
                }
                if (
                    _approval[i].active == true && _approval[i].claimed == false
                ) {
                    if (_approval[i].approvalId == approvalId_) {
                        // transfer erc20
                        if (
                            keccak256(
                                abi.encodePacked((_approval[i].token.tokenType))
                            ) == keccak256(abi.encodePacked(("ERC20")))
                        ) {
                            setApprovalClaimed(uid, _approval[i].approvalId);
                            TokenActions.sendERC20(_approval[i]);
                        }

                        // transfer erc721
                        if (
                            keccak256(
                                abi.encodePacked((_approval[i].token.tokenType))
                            ) == keccak256(abi.encodePacked(("ERC721")))
                        ) {
                            IERC721 ERC721 = IERC721(
                                _approval[i].token.tokenAddress
                            );
                            _approval[i].claimed = true;
                            setApprovalClaimed(uid, _approval[i].approvalId);

                            ERC721.safeTransferFrom(
                                _approval[i].approvedWallet,
                                _approval[i].beneficiary.beneficiaryAddress,
                                _approval[i].token.tokenId
                            );
                        }

                        // transfer erc1155
                        if (
                            keccak256(
                                abi.encodePacked((_approval[i].token.tokenType))
                            ) == keccak256(abi.encodePacked(("ERC1155")))
                        ) {
                            IERC1155 ERC1155 = IERC1155(
                                _approval[i].token.tokenAddress
                            );
                            uint256 _tokenAmount = (
                                _approval[i].approvedTokenAmount
                            );

                            bytes memory data;
                            _approval[i].claimed = true;
                            setApprovalClaimed(uid, _approval[i].approvalId);

                            ERC1155.safeTransferFrom(
                                _approval[i].approvedWallet,
                                _approval[i].beneficiary.beneficiaryAddress,
                                _approval[i].token.tokenId,
                                _tokenAmount,
                                data
                            );
                        }

                        break;
                    }
                }
            }
        }
    }

    /**
     * @dev sendAssetsToCharity
     * @param _charityBeneficiaryAddress address of the charity beneficiary
     * @param _uid the uid stored for the user
     *
     * Send assets to the charity beneficiary if they exist;
     *
     */
    function sendAssetsToCharity(
        address _charityBeneficiaryAddress,
        string memory _uid
    ) external onlyRelayerContract nonReentrant {
        // look to see if this address is a charity
        Approvals[]
            storage charityBeneficiaryApprovals = BeneficiaryClaimableAsset[
                _charityBeneficiaryAddress
            ];
        if (charityBeneficiaryApprovals.length == 0) {
            revert(Errors.AS_NO_APPROVALS);
        }
        for (uint256 i = 0; i < charityBeneficiaryApprovals.length; i++) {
            if (!charityBeneficiaryApprovals[i].beneficiary.isCharity) {
                revert(Errors.AS_NOT_CHARITY);
            }
            if (
                charityBeneficiaryApprovals[i].active == true &&
                charityBeneficiaryApprovals[i].claimed == false &&
                (keccak256(
                    abi.encodePacked(
                        (charityBeneficiaryApprovals[i].token.tokenType)
                    )
                ) == keccak256(abi.encodePacked(("ERC20"))))
            ) {
                setApprovalClaimed(
                    _uid,
                    charityBeneficiaryApprovals[i].approvalId
                );
                setBenApprovalClaimed(
                    _charityBeneficiaryAddress,
                    charityBeneficiaryApprovals[i].approvalId
                );
                TokenActions.sendERC20(charityBeneficiaryApprovals[i]);
            }
        }
    }

    /**
     * @dev getClaimableAssets allows users to get all claimable assets for a specific user.
     * @return return a list of assets being protected by this contract
     */
    function getClaimableAssets() external view returns (Token[] memory) {
        Approvals[] memory _approval = BeneficiaryClaimableAsset[msg.sender];
        uint256 _tokensCount = 0;
        uint256 _index = 0;

        for (uint256 k = 0; k < _approval.length; k++) {
            if (_approval[k].claimed == false && _approval[k].active == true) {
                _tokensCount++;
            }
        }
        Token[] memory _tokens = new Token[](_tokensCount);
        for (uint256 i = 0; i < _approval.length; i++) {
            if (_approval[i].claimed == false && _approval[i].active == true) {
                _tokens[_index] = _approval[i].token;
                _index++;
            }
        }
        return _tokens;
    }

    /**
     *  @notice setApprovalActive called by external actor to mark claiming period
     *  is active and ready
     *  @param uid string of the dApp identifier for the user
     *
     */
    function setApprovalActive(string memory uid)
        external
        onlyChainlinkOperationsContract
    {
        Approvals[] storage _approvals = MemberApprovals[uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            _approvals[i].active = true;
            _approvals[i].claimExpiryTime = block.timestamp + 31536000;
            Approvals[] storage approvals = BeneficiaryClaimableAsset[
                _approvals[i].beneficiary.beneficiaryAddress
            ];
            for (uint256 j = 0; j < approvals.length; j++) {
                if (
                    keccak256(abi.encodePacked((approvals[j].Member.uid))) ==
                    keccak256(abi.encodePacked((uid)))
                ) {
                    /// @notice check if is ERC20 for preAllocating then claiming
                    if (
                        keccak256(
                            abi.encodePacked((approvals[j].token.tokenType))
                        ) == keccak256(abi.encodePacked(("ERC20")))
                    ) {
                        IERC20 claimingERC20 = IERC20(
                            approvals[j].token.tokenAddress
                        );
                        /// @notice setting fixed tokenAmount to claim later
                        approvals[j].approvedTokenAmount =
                            (approvals[j].token.tokensAllocated *
                                claimingERC20.balanceOf(
                                    approvals[j].approvedWallet
                                )) /
                            100;
                    }

                    if (
                        keccak256(
                            abi.encodePacked((approvals[j].token.tokenType))
                        ) == keccak256(abi.encodePacked(("ERC1155")))
                    ) {
                        IERC1155 claimingERC1155 = IERC1155(
                            approvals[j].token.tokenAddress
                        );
                        approvals[j].approvedTokenAmount =
                            (approvals[j].token.tokensAllocated *
                                claimingERC1155.balanceOf(
                                    approvals[j].approvedWallet,
                                    approvals[j].token.tokenId
                                )) /
                            100;
                    }

                    approvals[j].active = true;
                    approvals[j].claimExpiryTime = block.timestamp + 31536000;

                    emit ApprovalsEvent(
                        approvals[j].Member.uid,
                        approvals[j].approvedWallet,
                        approvals[j].beneficiary.beneficiaryName,
                        approvals[j].beneficiary.beneficiaryAddress,
                        // approvals[j].beneficiary.isCharity,
                        approvals[j].token.tokenId,
                        approvals[j].token.tokenAddress,
                        approvals[j].token.tokenType,
                        approvals[j].token.tokensAllocated,
                        approvals[j].dateApproved,
                        approvals[j].claimed,
                        approvals[j].active,
                        approvals[j].approvalId,
                        approvals[j].claimExpiryTime,
                        approvals[j].approvedTokenAmount
                    );
                }
            }
        }
    }

    /**
     * @dev deleteApprooval - Deletes the approval of the specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 id of the approval struct to be deleted
     *
     */
    function deleteApproval(string memory uid, uint256 approvalId) external {
        Approvals[] storage approval_ = MemberApprovals[uid];
        for (uint256 i = 0; i < approval_.length; i++) {
            if (approval_[i].approvalId == approvalId) {
                Approvals[] storage _approval_ = MemberApprovals[uid];
                for (uint256 j = i; j < _approval_.length - 1; j++) {
                    _approval_[j] = _approval_[j + 1];
                }
                _approval_.pop();
                approval_ = _approval_;

                Approvals[] storage _benApproval = BeneficiaryClaimableAsset[
                    approval_[i].beneficiary.beneficiaryAddress
                ];
                for (uint256 k = 0; k < _benApproval.length; k++) {
                    if (_benApproval[k].approvalId == approvalId) {
                        Approvals[]
                            storage _benapproval_ = BeneficiaryClaimableAsset[
                                _benApproval[k].beneficiary.beneficiaryAddress
                            ];
                        for (uint256 l = k; k < _benapproval_.length - 1; k++) {
                            _benapproval_[l] = _benapproval_[l + 1];
                        }
                        _benapproval_.pop();
                        _benApproval = _benapproval_;
                        break;
                    }
                }
                break;
            }
        }
    }

    /**
     * @dev editApproval - Edits the token information of the approval
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 ID of the approval struct to modify
     * @param _contractAddress address being set for the approval
     * @param _tokenId uint256 tokenId being set of the approval
     * @param _tokenAmount uint256 amount of tokens in the approval
     * @param _tokenType string (ERC20 | ERC1155 | ERC721)
     *
     */
    function editApproval(
        string memory uid,
        uint256 approvalId,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        string memory _tokenType
    ) external checkIfMember(uid) {
        IMember(IProtocolDirectory(directoryContract).getMemberContract())
            .checkUIDofSender(uid, msg.sender);
        Approvals[] storage approval_ = MemberApprovals[uid];
        for (uint256 i = 0; i < approval_.length; i++) {
            if (approval_[i].approvalId == approvalId) {
                if (approval_[i].active || approval_[i].claimed) {
                    revert(Errors.AS_INVALID_APPROVAL);
                }

                TokenActions.checkAssetContract(_contractAddress, _tokenType);
                if (_tokenAmount > 100 || _tokenAmount < 0) {
                    revert(Errors.AS_INVALID_TOKEN_RANGE);
                }
                approval_[i].token.tokenAddress = _contractAddress;
                approval_[i].token.tokenId = _tokenId;
                approval_[i].token.tokensAllocated = _tokenAmount;
                approval_[i].token.tokenType = _tokenType;

                emit ApprovalsEvent(
                    approval_[i].Member.uid,
                    approval_[i].approvedWallet,
                    approval_[i].beneficiary.beneficiaryName,
                    approval_[i].beneficiary.beneficiaryAddress,
                    // approval_[i].beneficiary.isCharity,
                    _tokenId,
                    _contractAddress,
                    _tokenType,
                    _tokenAmount,
                    approval_[i].dateApproved,
                    approval_[i].claimed,
                    approval_[i].active,
                    approvalId,
                    approval_[i].claimExpiryTime,
                    0
                );

                Approvals[]
                    storage _beneficiaryApproval = BeneficiaryClaimableAsset[
                        approval_[i].beneficiary.beneficiaryAddress
                    ];
                for (uint256 j = 0; j < _beneficiaryApproval.length; j++) {
                    if (_beneficiaryApproval[j].approvalId == approvalId) {
                        if (
                            _beneficiaryApproval[j].active ||
                            _beneficiaryApproval[j].claimed
                        ) {
                            revert(Errors.AS_INVALID_APPROVAL);
                        }
                        _beneficiaryApproval[j]
                            .token
                            .tokenAddress = _contractAddress;
                        _beneficiaryApproval[j].token.tokenId = _tokenId;
                        _beneficiaryApproval[j]
                            .token
                            .tokensAllocated = _tokenAmount;
                        _beneficiaryApproval[j].token.tokenType = _tokenType;
                        break;
                    }
                }
                break;
            }
        }
        IMembership(IMembershipAddress).redeemUpdate(uid);
    }

    /**
     * @notice Function to check if user has membership
     * @param _uid string of the dApp identifier for the user
     *
     */

    function checkUserHasMembership(string memory _uid) public view {
        IMembership _membership = IMembership(IMembershipAddress);
        bool _MembershipActive = _membership.checkIfMembershipActive(_uid);
        if (_MembershipActive == false) {
            revert(Errors.AS_NO_MEMBERSHIP);
        } else {
            MembershipStruct memory Membership = IMembership(IMembershipAddress)
                .getMembership(_uid);
            if (Membership.updatesPerYear <= 0) {
                revert(Errors.AS_NEED_TOP);
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../structs/ApprovalsStruct.sol";

/**
 * @title TokenActions Library
 *
 * Here contains the common functions for interacting with
 * tokens for importing in different parts of the ecosystem
 * to save space hopefully in other places
 */
library TokenActions {
    /**
     * @notice internal function for sending erc20s
     *
     * creating this function to save space while sending coins
     * to charities and for beneficiaries
     *
     * @param _approval of the Approvals type in storage
     */
    function sendERC20(Approvals storage _approval) internal {
        IERC20 ERC20 = IERC20(_approval.token.tokenAddress);

        /// @notice gather the preset approved token amount for this beneficiary
        uint256 _tokenAmount = (_approval.approvedTokenAmount);

        /// @notice If the allowance for the member by claimer is greater than the _tokenAmount
        /// take the allowance for the beneficiary that called this function: why ?
        if (
            ERC20.allowance(_approval.approvedWallet, msg.sender) > _tokenAmount
        ) {
            _tokenAmount = ERC20.allowance(
                _approval.approvedWallet,
                msg.sender
            );
        }
        _approval.claimed = true;
        bool send = ERC20.transferFrom(
            _approval.approvedWallet,
            _approval.beneficiary.beneficiaryAddress,
            _tokenAmount
        );
    }

    /**
     *
     * @dev checkAssetContract
     * @param _contractAddress contract of the token we are checking
     * @param _tokenType the given tokentype as a string ERC721 etc...
     *
     * Checks if the assets passed through are assets of the determined type or not.
     * it can handle upgradable versions as well if needed
     *
     */
    function checkAssetContract(
        address _contractAddress,
        string memory _tokenType
    ) external view {
        if (
            (keccak256(abi.encodePacked((_tokenType))) ==
                keccak256(abi.encodePacked(("ERC721"))))
        ) {
            require(
                (IERC721Upgradeable(_contractAddress).supportsInterface(
                    type(IERC721Upgradeable).interfaceId
                ) ||
                    IERC721(_contractAddress).supportsInterface(
                        type(IERC721).interfaceId
                    )),
                "Does not support a Supported ERC721 Interface"
            );
        } else if (
            keccak256(abi.encodePacked((_tokenType))) ==
            keccak256(abi.encodePacked(("ERC20")))
        ) {
            require(
                (IERC20(_contractAddress).totalSupply() >= 0 ||
                    IERC20Upgradeable(_contractAddress).totalSupply() >= 0),
                "Is not an ERC20 Contract Address"
            );
        } else if (
            keccak256(abi.encodePacked((_tokenType))) ==
            keccak256(abi.encodePacked(("ERC1155")))
        ) {
            require(
                (IERC1155Upgradeable(_contractAddress).supportsInterface(
                    type(IERC1155Upgradeable).interfaceId
                ) ||
                    IERC1155(_contractAddress).supportsInterface(
                        type(IERC1155).interfaceId
                    )),
                "Does not support a Supported ERC1155 Interface"
            );
        } else {
            revert("Invalid token type");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts of the Webacy
 * @dev inspired by Aave's https://github.com/aave/protocol-v2/blob/master/contracts/protocol/libraries/helpers/Errors.sol
 * @dev Error messages prefix glossary:
 *  - ASF = AssetStoreFactory
 *  - MF = MembershipFactory
 *  - BL = Blacklist
 *  - WL = Whitelist
 *  - AS = AssetStore
 *  - CO = ChainlinkOperations
 *  - M = Member
 *  - MS = Membership
 *  - PD = ProtocolDirectory
 *  - RC = RelayerContract
 */
library Errors {
    // AssetStoreFactory Errors
    string public constant ASF_NO_MEMBERSHIP_CONTRACT = "1"; // "User does not have a membership contract deployed"
    string public constant ASF_HAS_AS = "2"; // "User has an AssetStore"

    // MembershipFactory Errors
    string public constant MF_HAS_MEMBERSHIP_CONTRACT = "3"; //  "User already has a membership contract"
    string public constant MF_INACTIVE_PLAN = "4"; //  "Membership plan is no longer active"
    string public constant MF_NEED_MORE_DOUGH = "5"; //  "Membership cost send is not sufficient"

    // Blacklist Errors
    string public constant BL_BLACKLISTED = "6"; //  "Address is blacklisted"

    // AssetStore Errors
    string public constant AS_NO_MEMBERSHIP = "7"; //  "AssetsStore: User does not have a membership"
    string public constant AS_USER_DNE = "8"; //  "User does not exist"
    string public constant AS_ONLY_RELAY = "9"; //  "Only relayer contract can call this"
    string public constant AS_ONLY_CHAINLINK_OPS = "10"; //  "Only chainlink operations contract can call this"
    string public constant AS_DIFF_LENGTHS = "11"; // "Lengths of parameters need to be equal"
    string public constant AS_ONLY_PRIMARY_WALLET = "12"; // "Only the primary wallet can approve to store assets"
    string public constant AS_INVALID_TOKEN_RANGE = "13"; // "tokenAmount can only range from 0-100 percentage"
    string public constant AS_ONLY_BENEFICIARY = "14"; // "Only the designated beneficiary can claim assets"
    string public constant AS_NO_APPROVALS = "15"; // "No Approvals found"
    string public constant AS_NOT_CHARITY = "16"; // "is not charity"
    string public constant AS_INVALID_APPROVAL = "17"; // "Approval should not be active and should not be claimed in order to make changes"
    string public constant AS_NEED_TOP = "18"; // "User does not have sufficient topUp Updates in order to store approvals"

    // Member Errors
    string public constant M_NOT_OWNER = "19"; // "Member UID does not own this wallet Address"
    string public constant M_NOT_HOLDER = "20"; // "The user does not own a token of the supporting NFT Collection"
    string public constant M_USER_DNE = "21"; // "No user exists"
    string public constant M_UID_DNE = "22"; // "No UID found"
    string public constant M_INVALID_BACKUP = "23"; // "BackUp Wallet specified is not the users backup Wallet"
    string public constant M_NOT_MEMBER = "24"; // "Member: User does not have a membership"
    string public constant M_EMPTY_UID = "25"; // "UID is empty"
    string public constant M_PRIM_WALLET = "26"; // "You cannot delete your primary wallet"
    string public constant M_ALREADY_PRIM = "27"; // "Current Wallet is already the primary Wallet"
    string public constant M_DIFF_LENGTHS = "28"; // "Lengths of parameters need to be equal"
    string public constant M_BACKUP_FIRST = "29"; // "User should backup assets prior to executing panic button"
    string public constant M_NEED_TOP = "30"; // "User does not have sufficient topUp Updates in order to store approvals"
    string public constant M_INVALID_ADDRESS = "31"; // "Membership Error: User should have its deployed Membership Address"
    string public constant M_USER_MUST_WALLET = "32"; //"User should have a primary wallet prior to adding a backup wallet"
    string public constant M_USER_EXISTS = "33"; // User with UID already exists

    // Membership Errors
    string public constant MS_NEED_MORE_DOUGH = "34"; // "User needs to send sufficient amount to topUp"
    string public constant MS_INACTIVE = "35"; // "Membership inactive"

    // RelayerContract Errors
    string public constant RC_UNAUTHORIZED = "36"; // "Only relayer can invoke this function"
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Protocol Directory interface
 *
 * Use this interface in any contract that needs to find
 * the contract location for commonly used Webacy contracts
 *
 */

interface IProtocolDirectory {
    /**
     * @notice event for recording changes of contracts
     *
     */
    event AddressSet(bytes32 contractName, address indexed newContractAddress);

    /**
     * @notice get the address by a bytes32 location id
     * @param _contractName a bytes32 string
     *
     */
    function getAddress(bytes32 _contractName) external returns (address);

    /**
     * @notice setAddress
     * @param _contractName a bytes32 string
     * @param _contractLocation an address of to entrypoint of protocol contract
     *
     */
    function setAddress(bytes32 _contractName, address _contractLocation)
        external
        returns (address);

    /**
     * @notice ssetStoreFactory
     * @return address of protocol contract matching ASSET_STORE_FACTORY value
     *
     */
    function getAssetStoreFactory() external view returns (address);

    /**
     * @notice getMembershipFactory
     * @return address of protocol contract matching MEMBERSHIP_FACTORY value
     *
     */
    function getMembershipFactory() external view returns (address);

    /**
     * @notice getRelayerContract
     * @return address of protocol contract matching RELAYER_CONTRACT value
     *
     */
    function getRelayerContract() external view returns (address);

    /**
     * @notice getMemberContract
     * @return address of protocol contract matching MEMBER_CONTRACT value
     *
     */
    function getMemberContract() external view returns (address);

    /**
     * @notice getBlacklistContract
     * @return address of protocol contract matching BLACKLIST_CONTRACT value
     *
     */
    function getBlacklistContract() external view returns (address);

    /**
     * @notice getWhitelistContract
     * @return address of protocol contract matching WHITELIST_CONTRACT value
     *
     */
    function getWhitelistContract() external view returns (address);

    /**
     * @notice getTransferPool
     * @return address of protocol contract matching TRANSFER_POOL value
     *
     */
    function getTransferPool() external view returns (address);

    /**
     * @notice getChainlinkOperationsContract
     * @return address of protocol contract matching CHAINLINK_OPERATIONS_CON value
     *
     */
    function getChainlinkOperationsContract() external view returns (address);

    /**
     * @dev setAssetStoreFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setAssetStoreFactory(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setMembershipFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setMembershipFactory(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setRelayerContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setRelayerContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setMemberContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setMemberContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setBlacklistContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setBlacklistContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setWhitelistContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setWhitelistContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setTransferPool
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setTransferPool(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setChainlinkOperationsContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setChainlinkOperationsContract(address _contractLocation)
        external
        returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../structs/MemberStruct.sol";
import "../structs/BackupApprovalStruct.sol";

/**
 * @title Interface for IMember
 * @dev to interact with Member Contracts
 *
 */
interface IMember {
    /**
     * @dev createMember
     * @param  uid centrally stored id for user
     * @param _walletAddress walletAddress to add wallet and check blacklist
     *
     * Allows to create a member onChain with a unique UID passed.
     * Will revert if the _walletAddress passed in is blacklisted
     *
     */
    function createMember(string calldata uid, address _walletAddress) external;

    /**
     * @dev getMember
     * @param uid string for centrally located identifier
     * Allows to get member information stored onChain with a unique UID passed.
     * @return member struct for a given uid
     *
     */
    function getMember(string memory uid) external view returns (member memory);

    /**
     * @dev getAllMembers
     * Allows to get all member information stored onChain
     * @return allMembers a list of member structs
     *
     */
    function getAllMembers() external view returns (member[] memory);

    /**
     * @dev addWallet - Allows to add Wallet to the user
     * @param uid string for dApp user identifier
     * @param _wallet address wallet being added for given user
     * @param _primary bool whether or not this new wallet is the primary wallet
     *
     *
     */
    function addWallet(
        string calldata uid,
        address _wallet,
        bool _primary
    ) external;

    /**
     * @dev getWallets
     * Allows to get all wallets of the user
     * @param uid string for dApp user identifier
     * @return address[] list of wallets
     *
     */
    function getWallets(string calldata uid)
        external
        view
        returns (address[] memory);

    /**
     * @dev deleteWallet - Allows to delete  wallets of a specific user
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function deleteWallet(string calldata uid, uint256 _walletIndex) external;

    /**
     * @dev getPrimaryWallets
     * Allows to get primary wallet of the user
     * @param uid string for dApp user identifier
     * @return address of the primary wallet per user
     *
     */
    function getPrimaryWallet(string memory uid)
        external
        view
        returns (address);

    /**
     * @dev setPrimaryWallet
     * Allows to set a specific wallet as the primary wallet
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function setPrimaryWallet(string calldata uid, uint256 _walletIndex)
        external;

    /**
     * @notice Function to check if wallet exists in the UID
     * @param _uid string of dApp identifier for a user
     * @param _user address of the user checking exists
     * Fails if not owner uid and user address do not return a wallet
     *
     */
    function checkUIDofSender(string memory _uid, address _user) external view;

    /**
     * @dev checkIfUIDExists
     * Check if user exists for specific wallet address already internal function
     * @param _walletAddress wallet address of the user
     * @return _exists - A boolean if user exists or not
     *
     */
    function checkIfUIDExists(address _walletAddress)
        external
        view
        returns (bool _exists);

    /**
     * @dev getUID
     * Allows user to pass walletAddress and return UID
     * @param _walletAddress get the UID of the user's if their wallet address is present
     * @return string of the ID used in the dApp to identify they user
     *
     */
    function getUID(address _walletAddress)
        external
        view
        returns (string memory);

    /**
     * @dev getBackupApprovals - function to return all backupapprovals for a specific UID
     * @param uid string of identifier for user in dApp
     * @return BackUpApprovals[] list of BackUpApprovals struct
     *
     */
    function getBackupApprovals(string memory uid)
        external
        view
        returns (BackUpApprovals[] memory);

    /**
     * @dev storeBackupAssetsApprovals - Function to store All Types Approvals by the user for backup
     *
     * @param _contractAddress address[] Ordered list of contract addresses for assets
     * @param _tokenIds uint256[] Ordered list of tokenIds associated with contract addresses
     * @param _backUpWallets address[] Ordered list of wallet addresses to backup assets
     * @param _tokenAmount uint256[] Ordered list of amounts per asset contract and token id to protext
     * @param _tokenTypes string[] Ordered list of strings i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string for dApp user identifier
     * @param _userAddress address of the user
     * @param _super bool true if function is being called from a parent function. false if directly
     *
     */
    function storeBackupAssetsApprovals(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID,
        address _userAddress,
        bool _super
    ) external;

    /**
     * @dev executePanic - Public function to transfer assets from one user to another
     * @param _backUpWallet wallet to panic send assets to
     * @param _memberUID uid of the user's assets being moved
     *
     */
    function executePanic(address _backUpWallet, string memory _memberUID)
        external;

    /**
     * @dev editBackup - Function to edit individual backup approvals
     * @param approvalId_ uint256 id to lookup Approval and edit
     * @param _contractAddress address contractAddress of asset to save
     * @param _tokenIds uint256 tokenId of asset
     * @param _tokenAmount uint256 amount of specific token
     * @param _tokenType string type of the token i.e. ERC20 | ERC721 | ERC1155
     * @param _uid string of identifier for user in dApp
     * @param _user address of the user of the dApp
     *
     */
    function editBackUp(
        uint256 approvalId_,
        address _contractAddress,
        uint256 _tokenIds,
        uint256 _tokenAmount,
        string calldata _tokenType,
        string memory _uid,
        address _user
    ) external;

    /**
     * @dev editAllBackUp - Function to delete and add new approvals for backup
     * @param _contractAddress address[] Ordered list of addresses for asset contracts
     * @param _tokenIds uint256[] Ordered list of tokenIds to backup
     * @param _backUpWallets address[] Ordered list of wallets that can be backups
     * @param _tokenAmount uint256[] Ordered list of amounts of tokens to backup
     * @param _tokenTypes string[] Ordered list of string tokenTypes i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string of identifier for user in dApp
     * @param _user address of the user of the dApp
     *
     *
     */
    function editAllBackUp(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID,
        address _user
    ) external;

    /**
     * @dev deleteAllBackUp - Function to delete all backup approvals
     * @param _uid string of identifier for user in dApp
     *
     */
    function deleteAllBackUp(string memory _uid) external;

    /**
     * @notice checkUserHasMembership - Function to check if user has membership
     * @param _uid string of identifier for user in dApp
     * @param _user address of the user of the dApp
     *
     */
    function checkUserHasMembership(string memory _uid, address _user)
        external
        view;

    /**
     * @dev Function set MembershipAddress for a Uid
     * @param _uid string of identifier for user in dApp
     * @param _Membership address of the user's associated membership contract
     *
     */
    function setIMembershipAddress(string memory _uid, address _Membership)
        external;

    /**
     * @dev Function to get MembershipAddress for a given Uid
     * @param _uid string of identifier for user in dApp
     *
     */
    function getIMembershipAddress(string memory _uid)
        external
        view
        returns (address);

    /**
     * @notice checkIfWalletHasNFT
     * verify if the user has specific nft 1155 or 721
     * @param _contractAddress address of asset contract
     * @param _NFTType string i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId checking for ownership
     * @param userAddress address address to verify ownership of
     * Fails if not owner
     */
    function checkIfWalletHasNFT(
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        address userAddress
    ) external view;

    /**
     * @dev addBackUpWallet - Allows to add backUp Wallets to the user
     * @param uid string for dApp user identifier
     * @param _wallets addresses of wallets being added for given user
     *
     *
     */
    function addBackupWallet(
        string calldata uid,
        address[] memory _wallets,
        address _user
    ) external;

    /**
     * @dev getBackupWallets - Returns backup Wallets for the specific UID
     * @param uid string for dApp user identifier
     *
     */
    function getBackupWallets(string calldata uid)
        external
        view
        returns (address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../structs/MembershipPlansStruct.sol";
import "../structs/MembershipStruct.sol";

/**
 * @title Interface for IMembership
 * @dev to interact with Membership
 */
interface IMembership {
    /**
     * @dev Function to check of membership is active for the user
     * @param _uid string identifier of user across dApp
     * @return bool boolean representing if the membership has expired
     *
     */
    function checkIfMembershipActive(string memory _uid)
        external
        view
        returns (bool);

    /**
     * @dev renewmembership Function to renew membership of the user
     * @param _uid string identifier of the user renewing membership
     *
     *
     */
    function renewMembership(string memory _uid) external payable;

    /**
     * @dev renewmembershipNFT - Function to renew membership for users that have NFTs
     * @param _contractAddress address of nft to approve renewing
     * @param _NFTType string type of NFT i.e. ERC20 | ERC1155 | ERC721
     * @param tokenId uint256 tokenId being protected
     * @param _uid string identifier of the user renewing membership
     *
     */
    function renewMembershipNFT(
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        string memory _uid
    ) external payable;

    /**
     * @dev Function to top up updates
     * @param _uid string identifier of the user across the dApp
     *
     */
    function topUpUpdates(string memory _uid) external payable;

    /**
     * @notice changeMembershipPlan
     * Ability to change membership plan for a member given a membership ID and member UID.
     * It is a payable function given the membership cost for the membership plan.
     *
     * @param membershipId uint256 id of membership plan changing to
     * @param _uid string identifier of the user
     */
    function changeMembershipPlan(uint256 membershipId, string memory _uid)
        external
        payable;

    /**
     * @notice changeMembershipPlanNFT - Function to change membership plan to an NFT based plan
     * @param membershipId uint256 id of the membershipPlan changing to
     * @param _contractAddress address of the NFT granting the membership
     * @param _NFTType string type of NFT i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId of the nft to verify ownership
     * @param _uid string identifier of the user across the dApp
     *
     */
    function changeMembershipPlanNFT(
        uint256 membershipId,
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        string memory _uid
    ) external payable;

    /**
     * @notice redeemUpdate
     * @param _uid string identifier of the user across the dApp
     *
     * Function to claim that a membership has been updated
     */
    function redeemUpdate(string memory _uid) external;

    /**
     * @notice Function to return membership information of the user
     * @param _uid string identifier of user across dApp
     * @return MembershipStruct containing information of the specific user's membership
     *
     */
    function getMembership(string memory _uid)
        external
        view
        returns (MembershipStruct memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../structs/ApprovalsStruct.sol";

/**
 *  @title IAssetStore
 *  @dev Interface for IAssetStore to interact with AssetStore Contracts
 *
 */
interface IAssetStore {
    /**
     * @notice storeAssetsApprovals - Function to store All Types Approvals by the user
     * @dev All of the arrays passed in need to be IN ORDER
     * they will be accessed in a loop together
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _memberUID string of the dApp identifier for the user
     *
     */
    function storeAssetsApprovals(
        address[] memory _contractAddress,
        uint256[] memory _tokenIds,
        address[] memory _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        uint256[] memory _tokenAmount,
        string[] memory _tokenTypes,
        string memory _memberUID
    ) external;

    /**
     * @notice getApproval - Function to get a specific token Approval for the user passing in UID and ApprovalID
     * @dev searches state for a match by uid and approvalId for a given user
     *
     * @param uid string of the dApp identifier for the user
     * @param approvalId number of the individual approval to lookup
     *
     * @return approval_ struct storing information for an Approval
     */
    function getApproval(string memory uid, uint256 approvalId)
        external
        view
        returns (Approvals memory approval_);

    /**
     * @notice getBeneficiaryApproval - Function to get a token Approval for the beneficiaries - Admin function
     * @param _benAddress address to lookup a specific list of approvals for given beneficiary address
     * @return approval_ a list of approval structs for a specific address
     */
    function getBeneficiaryApproval(address _benAddress)
        external
        view
        returns (Approvals[] memory approval_);

    /**
     * @notice getApprovals - Function to get all token Approvals for the user
     * @param uid string of the dApp identifier for the user
     * @return Approvals[] a list of all the approval structs associated with a user
     */
    function getApprovals(string memory uid)
        external
        view
        returns (Approvals[] memory);

    /**
     *  @notice setApprovalActive called by external actor to mark claiming period
     *  is active and ready
     *  @param uid string of the dApp identifier for the user
     *
     */
    function setApprovalActive(string memory uid) external;

    /**
     * @dev claimAsset - Function to claim Asset from a specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId_ uint256 id of the specific approval being claimed
     * @param benUID string of the dApp identifier for the beneficiary claiming the asset
     *
     */
    function claimAsset(
        string memory uid,
        uint256 approvalId_,
        string memory benUID
    ) external;

    /**
     * @dev getClaimableAssets allows users to get all claimable assets for a specific user.
     * @return return a list of assets being protected by this contract
     */
    function getClaimableAssets() external view returns (Token[] memory);

    /**
     * @dev deleteApprooval - Deletes the approval of the specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 id of the approval struct to be deleted
     *
     */
    function deleteApproval(string memory uid, uint256 approvalId) external;

    /**
     * @dev editApproval - Edits the token information of the approval
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 ID of the approval struct to modify
     * @param _contractAddress address being set for the approval
     * @param _tokenId uint256 tokenId being set of the approval
     * @param _tokenAmount uint256 amount of tokens in the approval
     * @param _tokenType string (ERC20 | ERC1155 | ERC721)
     *
     */
    function editApproval(
        string memory uid,
        uint256 approvalId,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        string memory _tokenType
    ) external;

    /**
     * @notice Function to store All Types of Approvals and Backups by the user in one function
     * @dev storeAssetsAndBackUpApprovals calls
     *  storeBackupAssetsApprovals & storeAssetsApprovals
     * 
     * sent to storeAssetsApprovals:
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     
     * sent to storeBackupAssetsApprovals:
     * @param _backUpTokenIds uint256[] Ordered list of tokenIds to be in a backup plan
     * @param _backupTokenAmount uint256[] Ordered list representing a magnitube of tokens to be in a backupPlan
     * @param _backUpWallets address[] Ordered list of destination wallets for the backupPlan
     * @param _backUpAddresses address[] Ordered list of contract addresses of assets for the backupPlan
     * @param _backupTokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param uid string of the dApp identifier for the user
     * 
     * 
     */
    function storeAssetsAndBackUpApprovals(
        address[] memory _contractAddress,
        address[] memory _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        string[] memory _tokenTypes,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenAmount,
        uint256[] memory _backUpTokenIds,
        uint256[] memory _backupTokenAmount,
        address[] memory _backUpWallets,
        address[] memory _backUpAddresses,
        string[] memory _backupTokenTypes,
        string memory uid
    ) external;

    /**
     * @notice transferUnclaimedAsset - Function to claim Unclaimed Assets passed the claimable expiry time
     * @param uid string of the dApp identifier for the user
     */
    function transferUnclaimedAssets(string memory uid) external;

    /**
     * @dev sendAssetsToCharity
     * @param _charityBeneficiaryAddress address of the charity beneficiary
     * @param _uid the uid stored for the user
     *
     * Send assets to the charity beneficiary if they exist;
     *
     */
    function sendAssetsToCharity(
        address _charityBeneficiaryAddress,
        string memory _uid
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../structs/MembershipPlansStruct.sol";

/**
 * @title IMembershipFactory
 * @dev Interface to interact with Membership Factory
 *
 */
interface IAssetStoreFactory {
    /**
     * @dev Function to deployAssetStore for each user
     * @param _uid string identifier of the user across the dApp
     * @param _user address of the user deploying the AssetStore
     *
     */
    function deployAssetStore(string memory _uid, address _user) external;

    /**
     * @dev Function to return assetStore Address of a specific user
     * @param _uid string identifier for the user across the dApp
     * @return address of the AssetStore for given user
     *
     */
    function getAssetStoreAddress(string memory _uid)
        external
        view
        returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Member Structure stores all member information
 * @param uid string For storing UID that cross references UID from DB for loading off-chain data
 * @param dateCreated uint256 timestamp of creation of User
 * @param wallets address[] Maintains an array of backUpWallets of the User
 * @param primaryWallet uint256 index of where in the wallets array the primary wallet exists
 */
struct member {
    string uid;
    uint256 dateCreated;
    address[] wallets;
    address[] backUpWallets;
    uint256 primaryWallet;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Token struct
 *
 * @param tokenId uint256 specific tokenId for the asset
 * @param tokenAddress address of the contract for this asset
 * @param tokenType string representing asset type i.e. ERC721 | ERC20 | ERC1155
 * @param tokensAllocated uint256 number representing how many tokens as a %'s to
 * attach to a given approval or other directive
 */
struct Token {
    uint256 tokenId;
    address tokenAddress;
    string tokenType;
    uint256 tokensAllocated;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./MemberStruct.sol";
import "./TokenStruct.sol";
import "./BeneficiaryStruct.sol";

/**
 * @dev Approvals Struct
 * @param Member member struct with information on the user
 * @param approvedWallet address of wallet approved
 * @param beneficiary Beneficiary struct holding recipient info
 * @param token Token struct holding specific info on the asset
 * @param dateApproved uint256 timestamp of the approval creation
 * @param claimed bool representing status if asset was claimed
 * @param active bool representing if the claim period has begun
 * @param approvalId uint256 id of the specific approval in the assetstore
 * @param claimExpiryTime uint256 timestamp of when claim period ends
 * @param approvedTokenAmount uint256 magnitude of tokens to claim by this approval
 *
 */
struct Approvals {
    member Member;
    address approvedWallet;
    Beneficiary beneficiary;
    Token token;
    uint256 dateApproved;
    bool claimed;
    bool active;
    uint256 approvalId;
    uint256 claimExpiryTime;
    uint256 approvedTokenAmount;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Structure to store different types of Beneficiary
 * (ERC721, ERC1155, ERC20)
 * @param beneficiaryAddress address for assets to go to
 * @param beneficiaryName name of entity recieveing the assets
 * @param isCharity boolean representing if Beneficiary is a charity
 * because charities will be a recieve only address and cannot be
 * expected to call a function to claim assets
 *
 */
struct Beneficiary {
    address beneficiaryAddress;
    string beneficiaryName;
    bool isCharity;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./MemberStruct.sol";
import "./TokenStruct.sol";
import "./BeneficiaryStruct.sol";

/**
 * @dev BackUpApprovals struct
 *
 * @param Member member struct of information for the user
 * @param approvedWallet address wallet approving the assets
 * @param backUpWallet address[] wallet approved to recieve assets
 * @param token Token struct with information about the asset backed up
 * @param dateApproved uint256 timestamp of when the approval came in
 * @param claimed bool status of the approval if it was claimed
 * @param approvalId uint256 id of the specific approval for this asset
 */
struct BackUpApprovals {
    member Member;
    address approvedWallet;
    address[] backUpWallet;
    Token token;
    uint256 dateApproved;
    bool claimed;
    uint256 approvalId;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev membershipPlan struct
 *
 * @param membershipDuration uint256 length of time membership is good for
 * @param costOfMembership uint256 cost in wei of gaining membership
 * @param updatesPerYear uint256 how many updates can the membership be updated in a year by user
 * @param nftCollection address pass as null address if it is not for creating specific
 * membership plan for a specific NFT Collection
 * @param membershipId uint256 id for the new membership to lookup by
 * @param active bool status if the membership can be used to create new contracts
 */
struct membershipPlan {
    uint256 membershipDuration;
    uint256 costOfMembership;
    uint256 updatesPerYear;
    address nftCollection;
    uint256 membershipId;
    bool active;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Membership Structure stores membership data of a member
 * @param user address of the user who has a membership
 * @param membershipStarted uint256 timestamp of when the membership began
 * @param membershipEnded uint256 timestamp of when membership expires
 * @param payedAmount uint256 amount in wei paid for the membership
 * @param active bool status of the user's membership
 * @param membershipId uint256 id of the membershipPlan this was created for
 * @param updatesPerYear uint256 how many updates per year left for the user
 * @param nftCollection address of the nft collection granting a membership or address(0)
 * @param uid string of the identifier of the user across the dApp
 *
 */
struct MembershipStruct {
    address user;
    uint256 membershipStarted;
    uint256 membershipEnded;
    uint256 payedAmount;
    bool active;
    uint256 membershipId;
    uint256 updatesPerYear;
    address nftCollection;
    string uid;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IBlacklist.sol";
import "../interfaces/IMembershipFactory.sol";
import "../interfaces/IProtocolDirectory.sol";
import "../structs/MembershipPlansStruct.sol";
import "../AssetsStore.sol";
import "../libraries/Errors.sol";

//DEV
//

/**
 * @title AssetStoreFactory
 * This contract will deploy AssetStore contracts for users.
 * Users will pass approvals to that contract and this
 * contract will update state with details and track who has
 * which contracts
 *
 *
 */
contract AssetStoreFactory is
    IAssetStoreFactory,
    Initializable,
    OwnableUpgradeable
{
    /// @dev Storing all AssetStore Contract Addresses
    address[] private AssetStoreContractAddresses;

    /// @dev ProtocolDirectory location
    address private directoryContract;

    /// @dev Mapping User to a Specific Contract Address
    mapping(string => address) private UserToAssetStoreContract;

    /**
     * @dev event AssetStoreCreated
     * @param user address the AssetStore was deployed on behalf of
     * @param assetStoreAddress address of the dpeloyed contract
     * @param uid string identifier for the user across the dApp
     *
     */
    event AssetStoreCreated(
        address user,
        address assetStoreAddress,
        string uid
    );

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract - to the protocol directory contract
     *
     */
    function initialize(address _directoryContract) external initializer {
        __Context_init_unchained();
        __Ownable_init();
        directoryContract = _directoryContract;
    }

    /**
     * @dev Function to deployAssetStore for each user
     * @param _uid string identifier of the user across the dApp
     * @param _user address of the user deploying the AssetStore
     *
     */
    function deployAssetStore(string memory _uid, address _user) external {
        address IBlacklistUsersAddress = IProtocolDirectory(directoryContract)
            .getBlacklistContract();
        IBlacklist(IBlacklistUsersAddress).checkIfAddressIsBlacklisted(_user);
        address _userAddress = UserToAssetStoreContract[_uid];
        if (_userAddress != address(0)) {
            revert(Errors.ASF_HAS_AS);
        }

        IMember(IProtocolDirectory(directoryContract).getMemberContract())
            .checkUIDofSender(_uid, _user);
        address IMembershipFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getMembershipFactory();
        IMembershipFactory _membershipFactory = IMembershipFactory(
            IMembershipFactoryAddress
        );
        if (_membershipFactory.getUserMembershipAddress(_uid) == address(0)) {
            revert(Errors.ASF_NO_MEMBERSHIP_CONTRACT);
        }
        address _membershipAddress = _membershipFactory
            .getUserMembershipAddress(_uid);
        AssetsStore assetStore = new AssetsStore(
            directoryContract,
            _membershipAddress
        );
        AssetStoreContractAddresses.push(address(assetStore));
        UserToAssetStoreContract[_uid] = address(assetStore);

        emit AssetStoreCreated(_user, address(assetStore), _uid);
    }

    /**
     * @dev Function to return assetStore Address of a specific user
     * @param _uid string identifier for the user across the dApp
     * @return address of the AssetStore for given user
     */
    function getAssetStoreAddress(string memory _uid)
        external
        view
        returns (address)
    {
        return UserToAssetStoreContract[_uid];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IBlacklist
 * @dev To interact with Blacklist Users Contracts
 */
interface IBlacklist {
    /**
     * @dev checkIfAddressIsBlacklisted
     * @param _user address of wallet to check is blacklisted
     *
     */
    function checkIfAddressIsBlacklisted(address _user) external view;

    /**
     * @dev Function to get blacklisted addresses
     * @return blackListAddresses address[]
     *
     */
    function getBlacklistedAddresses() external view returns (address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../structs/MembershipPlansStruct.sol";

/**
 * @title Interface for IMembershipFactory to interact with Membership Factory
 *
 */
interface IMembershipFactory {
    /**
     * @dev Function to createMembership by deploying membership contract for a specific member
     * @param uid string identifier of a user across the dApp
     * @param _membershipId uint256 id of the chosen membership plan
     * @param _walletAddress address of the user creating the membership
     *
     */
    function createMembership(
        string calldata uid,
        uint256 _membershipId,
        address _walletAddress
    ) external payable;

    /**
     * @dev Function to create Membership for a member with supporting NFTs
     * @param uid string identifier of the user across the dApp
     * @param _contractAddress address of the NFT granting membership
     * @param _NFTType string type of NFT for granting membership i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId of the owned nft to verify ownership
     * @param _walletAddress address of the user creating a membership with their nft
     *
     */
    function createMembershipSupportingNFT(
        string calldata uid,
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        address _walletAddress
    ) external payable;

    /**
     * @dev function to get all membership plans
     * @return membershipPlan[] a list of all membershipPlans on the contract
     *
     */
    function getAllMembershipPlans()
        external
        view
        returns (membershipPlan[] memory);

    /**
     * @dev function to getCostOfMembershipPlan
     * @param _membershipId uint256 id of specific plan to retrieve
     * @return membershipPlan struct
     *
     */
    function getMembershipPlan(uint256 _membershipId)
        external
        view
        returns (membershipPlan memory);

    /**
     * @dev Function to get updates per year cost
     * @return uint256 cost of updating membership in wei
     *
     */
    function getUpdatesPerYearCost() external view returns (uint256);

    /**
     * @dev Function to set new membership plan for user
     * @param _uid string identifing the user across the dApp
     * @param _membershipId uint256 id of the membership for the user
     *
     */
    function setUserForMembershipPlan(string memory _uid, uint256 _membershipId)
        external;

    /**
     * @dev Function to transfer eth to specific pool
     *
     */
    function transferToPool() external payable;

    /**
     * @dev Function to return users membership contract address
     * @param _uid string identifier of a user across the dApp
     * @return address of the membership contract if exists for the _uid
     *
     */
    function getUserMembershipAddress(string memory _uid)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IWhitelist.sol";

/**
 * @title WhitelistUsers Contract
 * This contract contains information of which users are whitelisted
 * to interact with factory contracts and the rest of the protocol
 *
 *
 */
contract WhitelistUsers is
    IWhitelist,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _duration uint256 how long the membership is for whitelisted users
     * @param _updates uint256 representing how many updates whitelist users get
     *
     */
    function initialize(uint256 _duration, uint256 _updates)
        public
        initializer
    {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();

        whiteListUpdatesPerYear = _updates;
        whiteListDuration = _duration;
    }

    /// @dev whitelisted addresses
    address[] private whiteListAddresses;

    /// @dev whiteList duration
    uint256 whiteListDuration;

    /// @dev whiteList UpdatesPerYear given
    uint256 whiteListUpdatesPerYear;

    /**
     * @dev Function to get whitelisted addresses
     * @return list of addresses on the whitelist
     *
     */
    function getWhitelistAddress() external view returns (address[] memory) {
        return whiteListAddresses;
    }

    /**
     * @dev checkIfAddressIsWhitelisted
     * @param _user address of the user to verify is on the list
     * @return whitelisted boolean representing if the input is whitelisted
     *
     */
    function checkIfAddressIsWhitelisted(address _user)
        external
        view
        returns (bool whitelisted)
    {
        for (uint256 i = 0; i < whiteListAddresses.length; i++) {
            if (whiteListAddresses[i] == _user) {
                return whitelisted = true;
            }
        }
        whitelisted = false;
    }

    /**
     * @dev addWhiteList
     * @param _user address of the wallet to whitelist
     *
     */
    function addWhiteList(address _user) external onlyOwner {
        whiteListAddresses.push(_user);
    }

    /**
     * @dev removeWhiteList
     * @param _user address of the wallet to remove from the whitelist
     *
     */
    function removeWhiteList(address _user) external onlyOwner {
        for (uint256 i; i < whiteListAddresses.length; i++) {
            if (whiteListAddresses[i] == _user) {
                whiteListAddresses[i] = whiteListAddresses[
                    whiteListAddresses.length - 1
                ];
                whiteListAddresses.pop();
                break;
            }
        }
    }

    /**
     * @dev getWhitelistUpdatesPerYear
     * @return whiteListUpdatesPerYear uint256 for how many updates the whitelisted gets
     *
     */
    function getWhitelistUpdatesPerYear() external view returns (uint256) {
        return whiteListUpdatesPerYear;
    }

    /**
     * @dev getWhitelistDuration
     * @return whiteListDuration uint256 of how long the membership is for whitelisted users
     */
    function getWhitelistDuration() external view returns (uint256) {
        return whiteListDuration;
    }

    /**
     * @dev setWhitelistUpdatesPerYear
     * @param _updatesPerYear uint256 set how many updates a whitelisted user gets within a year
     *
     */
    function setWhitelistUpdatesPerYear(uint256 _updatesPerYear)
        external
        onlyOwner
    {
        whiteListUpdatesPerYear = _updatesPerYear;
    }

    /**
     * @dev setWhitelistDuration
     * @param _duration uint256 change the value of how long whitelisted memberships are
     */
    function setWhitelistDuration(uint256 _duration) external onlyOwner {
        whiteListDuration = _duration;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Interface for IWhitelist to interact with Whitelist Users Contracts
 *
 */
interface IWhitelist {
    /**
     * @dev getWhitelistUpdatesPerYear
     * @return whiteListUpdatesPerYear uint256 for how many updates the whitelisted gets
     *
     */
    function getWhitelistUpdatesPerYear() external view returns (uint256);

    /**
     * @dev getWhitelistDuration
     * @return whiteListDuration uint256 of how long the membership is for whitelisted users
     */
    function getWhitelistDuration() external view returns (uint256);

    /**
     * @dev checkIfAddressIsWhitelisted
     * @param _user address of the user to verify is on the list
     * @return whitelisted boolean representing if the input is whitelisted
     *
     */
    function checkIfAddressIsWhitelisted(address _user)
        external
        view
        returns (bool whitelisted);

    /**
     * @dev Function to get whitelisted addresses
     * @return list of addresses on the whitelist
     *
     */
    function getWhitelistAddress() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IBlacklist.sol";
import "../libraries/Errors.sol";

/**
 * @title Blacklist
 * Contract storing addresses of users who are not able
 * to interact with the ecosystem at certain points
 *
 */
contract Blacklist is
    IBlacklist,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     */
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @dev blacklisted addresses list
    address[] private blackListAddresses;

    /**
     * @dev Function to get blacklisted addresses
     * @return blackListAddresses address[]
     *
     */
    function getBlacklistedAddresses()
        external
        view
        returns (address[] memory)
    {
        return blackListAddresses;
    }

    /**
     * @dev checkIfAddressIsBlacklisted
     * @param _user address of wallet to check is blacklisted
     *
     */
    function checkIfAddressIsBlacklisted(address _user) external view {
        for (uint256 i = 0; i < blackListAddresses.length; i++) {
            if (blackListAddresses[i] == _user) {
                revert(Errors.BL_BLACKLISTED);
            }
        }
    }

    /**
     * @dev Function to add new wallet to blacklist
     * @param _user address of new blacklisted wallet
     *
     */
    function addBlacklist(address _user) external onlyOwner {
        blackListAddresses.push(_user);
    }

    /**
     * @dev Function to remove blacklist
     * @param _user address of user to remove from the list
     *
     */
    function removeBlacklist(address _user) external onlyOwner {
        for (uint256 i; i < blackListAddresses.length; i++) {
            if (blackListAddresses[i] == _user) {
                blackListAddresses[i] = blackListAddresses[
                    blackListAddresses.length - 1
                ];
                blackListAddresses.pop();
                break;
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Membership.sol";
import "../interfaces/IMembershipFactory.sol";
import "../interfaces/IProtocolDirectory.sol";
import "../interfaces/IWhitelist.sol";
import "../structs/MembershipPlansStruct.sol";
import "../libraries/Errors.sol";

//DEV
//

/**
 * @title MembershipFactory
 * This contract is responsible for deploying Membership contracts
 * on behalf of users within the ecosystem. This contract also contains
 * information to keep track of deployed contracts and versions/ status
 *
 */
contract MembershipFactory is
    IMembershipFactory,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @dev storing all addresses of membership plans
    address[] private membershipPlanAddresses;

    /// @dev Directory contract address
    address private directoryContract;

    /// @dev Variable to provide membershipId for user
    uint256 private membershipId;

    /// @dev Fixed cost for updatesPerYear
    uint256 private updatesPerYearCost;

    /// @dev Storing all membership factory states
    Membership[] private memberships;

    /// @dev storing all membership plans
    membershipPlan[] private membershipPlans;

    /// @dev  Mapping specific user to a membership plan id ; each user can have only one membership plan
    mapping(string => uint256) private UserToMembershipPlan;

    /// @dev Mapping specific plan to a membershipID
    mapping(uint256 => membershipPlan) private membershipIdtoPlan;

    /// @dev Mapping user to factory address of membership
    mapping(string => address) private UserToMembershipContract;

    /**
     * @dev event MembershipContractCreated
     *
     * @param membershipContractAddress address of the deployed membership contract
     * @param user address of the user the membership belongs to
     * @param uid string identifier of the user across the dApp
     * @param membershipCreatedDate uint256 timestamp of when the contract was deployed
     * @param membershipEndDate uint256 timestamp of when the membership expires
     * @param membershipId uint256 identifier of the specific membership the user got
     * @param updatesPerYear uint256 how many updates the user can use in a year
     * @param collectionAddress address of the nft membership contract if any or address(0)
     *
     */
    event MembershipContractCreated(
        address membershipContractAddress,
        address user,
        string uid,
        uint256 membershipCreatedDate,
        uint256 membershipEndDate,
        uint256 membershipId,
        uint256 updatesPerYear,
        address collectionAddress
    );

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of the protocol directory
     *
     */
    function initialize(address _directoryContract) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();
        directoryContract = _directoryContract;
        membershipId = 0;
        updatesPerYearCost = 3e17;
    }

    /**
     * @dev Function to return users membership contract address
     * @param _uid string identifier of a user across the dApp
     * @return address of the membership contract if exists for the _uid
     *
     */
    function getUserMembershipAddress(string memory _uid)
        external
        view
        returns (address)
    {
        return UserToMembershipContract[_uid];
    }

    /**
     * @dev Function to createMembership by deploying membership contract for a specific member
     * @param uid string identifier of a user across the dApp
     * @param _membershipId uint256 id of the chosen membership plan
     * @param _walletAddress address of the user creating the membership
     *
     */
    function createMembership(
        string calldata uid,
        uint256 _membershipId,
        address _walletAddress
    ) external payable nonReentrant {
        membershipPlan memory _membershipPlan = membershipIdtoPlan[
            _membershipId
        ];
        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();
        address _whitelistaddress = IProtocolDirectory(directoryContract)
            .getWhitelistContract();

        uint256 _createdDate = block.timestamp;
        uint256 _endedDate = block.timestamp +
            _membershipPlan.membershipDuration;
        bool _whitelistStatus = IWhitelist(_whitelistaddress)
            .checkIfAddressIsWhitelisted(_walletAddress);
        uint256 _updatesPerYear = _membershipPlan.updatesPerYear;
        if (_whitelistStatus == true) {
            _endedDate =
                block.timestamp +
                IWhitelist(_whitelistaddress).getWhitelistDuration();
            _updatesPerYear = IWhitelist(_whitelistaddress)
                .getWhitelistUpdatesPerYear();
        } else {
            if (msg.value != _membershipPlan.costOfMembership) {
                revert(Errors.MF_NEED_MORE_DOUGH);
            }
        }

        if (
            (IMember(IMemberAddress).checkIfUIDExists(_walletAddress) == false)
        ) {
            IMember(IMemberAddress).createMember(uid, _walletAddress);
        }
        if (UserToMembershipContract[uid] != address(0)) {
            revert(Errors.MF_HAS_MEMBERSHIP_CONTRACT);
        }
        if (!_membershipPlan.active) {
            revert(Errors.MF_INACTIVE_PLAN);
        }

        Membership _membership = new Membership(
            uid,
            directoryContract,
            _walletAddress,
            _createdDate,
            _endedDate,
            _membershipPlan.membershipId,
            _updatesPerYear,
            msg.value,
            _membershipPlan.nftCollection
        );
        memberships.push(_membership);
        UserToMembershipPlan[uid] = membershipId;
        UserToMembershipContract[uid] = address(_membership);
        membershipPlanAddresses.push(address(_membership));

        IMember(IMemberAddress).setIMembershipAddress(
            uid,
            address(_membership)
        );

        emit MembershipContractCreated(
            address(_membership),
            _walletAddress,
            uid,
            _createdDate,
            _endedDate,
            _membershipId,
            _updatesPerYear,
            address(0)
        );
        if (_whitelistStatus == false) {
            payable(IProtocolDirectory(directoryContract).getTransferPool())
                .transfer(msg.value);
        }
    }

    /**
     * @dev Function to create Membership for a member with supporting NFTs
     * @param uid string identifier of the user across the dApp
     * @param _contractAddress address of the NFT granting membership
     * @param _NFTType string type of NFT for granting membership i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId of the owned nft to verify ownership
     * @param _walletAddress address of the user creating a membership with their nft
     *
     */
    function createMembershipSupportingNFT(
        string calldata uid,
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        address _walletAddress
    ) external payable nonReentrant {
        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();

        if ((IMember(IMemberAddress).checkIfUIDExists(msg.sender) == false)) {
            IMember(IMemberAddress).createMember(uid, _walletAddress);
        }

        if (UserToMembershipContract[uid] != address(0)) {
            revert(Errors.MF_HAS_MEMBERSHIP_CONTRACT);
        }

        uint256 _amount = msg.value;

        for (uint256 i = 0; i < membershipPlans.length; i++) {
            if (membershipPlans[i].nftCollection == _contractAddress) {
                IMember(IMemberAddress).checkIfWalletHasNFT(
                    _contractAddress,
                    _NFTType,
                    tokenId,
                    _walletAddress
                );

                membershipPlan memory _membershipPlan = membershipIdtoPlan[
                    membershipPlans[i].membershipId
                ];
                if (!_membershipPlan.active) {
                    revert(Errors.MF_INACTIVE_PLAN);
                }
                if (_amount != _membershipPlan.costOfMembership) {
                    revert(Errors.MF_NEED_MORE_DOUGH);
                }

                uint256 _createdDate = block.timestamp;
                uint256 _endedDate = block.timestamp +
                    _membershipPlan.membershipDuration;

                Membership _membership = new Membership(
                    uid,
                    directoryContract,
                    _walletAddress,
                    _createdDate,
                    _endedDate,
                    _membershipPlan.membershipId,
                    _membershipPlan.updatesPerYear,
                    _amount,
                    _membershipPlan.nftCollection
                );
                memberships.push(_membership);
                UserToMembershipPlan[uid] = _membershipPlan.membershipId;
                UserToMembershipContract[uid] = address(_membership);
                membershipPlanAddresses.push(address(_membership));
                payable(IProtocolDirectory(directoryContract).getTransferPool())
                    .transfer(_amount);
                emit MembershipContractCreated(
                    address(_membership),
                    _walletAddress,
                    uid,
                    _createdDate,
                    _endedDate,
                    _membershipPlan.membershipId,
                    _membershipPlan.updatesPerYear,
                    _contractAddress
                );
                break;
            }
        }
    }

    /**
     * @dev Function to create a membership plan with an NFT or without
     * If no collection provide address(0) for _collection
     * @param _duration uint256 value of how long the membership is valid
     * @param _updatesPerYear uint256 how many times in a year can the membership be updated
     * @param _cost uint256 cost in wei of the membership
     * @param _collection address of the NFT to create a membershipPlan or address(0)
     *
     */
    function createMembershipPlan(
        uint256 _duration,
        uint256 _updatesPerYear,
        uint256 _cost,
        address _collection
    ) external onlyOwner {
        if (_collection == address(0)) {
            membershipPlan memory _membershipPlan = membershipPlan(
                _duration,
                _cost,
                _updatesPerYear,
                address(0),
                ++membershipId,
                true
            );
            membershipIdtoPlan[membershipId] = _membershipPlan;
            membershipPlans.push(_membershipPlan);
        } else {
            membershipPlan memory _membershipPlan = membershipPlan(
                _duration,
                _cost,
                _updatesPerYear,
                _collection,
                ++membershipId,
                true
            );
            membershipIdtoPlan[membershipId] = _membershipPlan;
            membershipPlans.push(_membershipPlan);
        }
    }

    /**
     * @dev function to make membership plan active/inactive
     * @param _active bool representing if the membershipPlan can be used to create new contracts
     * @param _membershipId uint256 id of the membershipPlan to activate
     *
     */
    function setMembershipPlanActive(bool _active, uint256 _membershipId)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < membershipPlans.length; i++) {
            if (membershipPlans[i].membershipId == _membershipId) {
                membershipPlans[i].active = _active;
            }
        }
    }

    /**
     * @dev function to get active/inactive status of membershipplan
     * @param _membershipId uint256 id of a membershipPlan
     * @return isActive a bool describing its status
     *
     */
    function getMembershipPlanActive(uint256 _membershipId)
        external
        view
        returns (bool isActive)
    {
        for (uint256 i = 0; i < membershipPlans.length; i++) {
            if (membershipPlans[i].membershipId == _membershipId) {
                isActive = membershipPlans[i].active;
            }
        }
    }

    /**
     * @dev function to get all membership plans
     * @return membershipPlan[] a list of all membershipPlans on the contract
     *
     */
    function getAllMembershipPlans()
        external
        view
        returns (membershipPlan[] memory)
    {
        return membershipPlans;
    }

    /**
     * @dev function to getCostOfMembershipPlan
     * @param _membershipId uint256 id of specific plan to retrieve
     * @return membershipPlan struct
     *
     */
    function getMembershipPlan(uint256 _membershipId)
        external
        view
        returns (membershipPlan memory)
    {
        return membershipIdtoPlan[_membershipId];
    }

    /**
     * @dev Function to get updates per year cost
     * @return uint256 cost of updating membership in wei
     *
     */
    function getUpdatesPerYearCost() external view returns (uint256) {
        return updatesPerYearCost;
    }

    /**
     * @dev Function to set new updates per year cost
     * @param _newCost uint256 in wei, how much updating the membership will be
     *
     */
    function setUpdatesPerYearCost(uint256 _newCost) external onlyOwner {
        updatesPerYearCost = _newCost;
    }

    /**
     * @dev Function to set new membership plan for user
     * @param _uid string identifing the user across the dApp
     * @param _membershipId uint256 id of the membership for the user
     *
     */
    function setUserForMembershipPlan(string memory _uid, uint256 _membershipId)
        external
    {
        UserToMembershipPlan[_uid] = _membershipId;
    }

    /**
     * @dev Function to transfer eth to specific pool
     *
     */
    function transferToPool() external payable {
        address transferPoolAddress = IProtocolDirectory(directoryContract)
            .getTransferPool();
        payable(transferPoolAddress).transfer(msg.value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IMember.sol";
import "./interfaces/IMembership.sol";
import "./interfaces/IMembershipFactory.sol";
import "./interfaces/IProtocolDirectory.sol";
import "./interfaces/IBlacklist.sol";
import "./structs/MembershipStruct.sol";

import "./libraries/Errors.sol";

//DEV

/**
 * @title Membership Contract
 * @notice contract deployed 1:1 per User wanting a membership with Webacy
 * contains data and information for interacting within the suite of products onchain
 *
 */

contract Membership is IMembership, ReentrancyGuard {
    // Support multiple ERC20 tokens

    // Membership Information of a specific user
    mapping(string => MembershipStruct) private membershipInfoOfAddress;

    address private directoryAddress;

    /**
     * @dev membershipUpdated event
     * @param membershipContractAddress address of the membershipContract emitting event
     * @param user address of user associated with this membership
     * @param uid string identifier of user across dApp
     * @param membershipCreatedDate uint256 timestamp of the membership being created
     * @param membershipEndDate uint256 timestamp of the set time to expire membership
     * @param membershipId uint256 id of the type of membership purchased
     * @param updatesPerYear uint256 the number of updates a user may have within 1 year
     * @param collectionAddress address of NFT granting membership to a user
     *
     */
    event membershipUpdated(
        address membershipContractAddress,
        address user,
        string uid,
        uint256 membershipCreatedDate,
        uint256 membershipEndDate,
        uint256 membershipId,
        uint256 updatesPerYear,
        address collectionAddress
    );

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param uid string identifier of user across dApp
     * @param _directoryAddress address of protocol directory contract
     * @param _userAddress address of the user attached to this membership contract
     * @param _membershipStartDate uint256 beginning timestamp of the membership
     * @param _membershipEndedDate uint256 expiry timestamp of the membership
     * @param _membershipId uint256 id of the type of membership purchased
     * @param updatesPerYear uint256 number of times within a year the membership can be updated
     * @param _membershipPayedAmount uint256 cost of membership initally
     * @param nftCollection address of asset for granting membership
     *
     */
    constructor(
        string memory uid,
        address _directoryAddress,
        address _userAddress,
        uint256 _membershipStartDate,
        uint256 _membershipEndedDate,
        uint256 _membershipId,
        uint256 updatesPerYear,
        uint256 _membershipPayedAmount,
        address nftCollection
    ) {
        directoryAddress = _directoryAddress;
        address IMemberAddress = IProtocolDirectory(_directoryAddress)
            .getMemberContract();
        if ((IMember(IMemberAddress).checkIfUIDExists(_userAddress) == false)) {
            IMember(IMemberAddress).createMember(uid, _userAddress);
        }

        MembershipStruct memory _membership = MembershipStruct(
            _userAddress,
            _membershipStartDate,
            _membershipEndedDate,
            _membershipPayedAmount,
            true,
            _membershipId,
            updatesPerYear,
            nftCollection,
            uid
        );
        membershipInfoOfAddress[uid] = _membership;
    }

    /**
     * @notice Function to return membership information of the user
     * @param _uid string identifier of user across dApp
     * @return MembershipStruct containing information of the specific user's membership
     *
     */
    function getMembership(string memory _uid)
        external
        view
        returns (MembershipStruct memory)
    {
        return membershipInfoOfAddress[_uid];
    }

    /**
     * @dev Function to check of membership is active for the user
     * @param _uid string identifier of user across dApp
     * @return bool boolean representing if the membership has expired
     *
     */
    function checkIfMembershipActive(string memory _uid)
        public
        view
        returns (bool)
    {
        return membershipInfoOfAddress[_uid].membershipEnded > block.timestamp;
    }

    /**
     * @dev renewmembership Function to renew membership of the user
     * @param _uid string identifier of the user renewing membership
     *
     *
     */
    function renewMembership(string memory _uid) external payable nonReentrant {
        IBlacklist(IProtocolDirectory(directoryAddress).getBlacklistContract())
            .checkIfAddressIsBlacklisted(msg.sender);
        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];
        IMember(IProtocolDirectory(directoryAddress).getMemberContract())
            .checkUIDofSender(_uid, msg.sender);
        address IMembershipFactoryAddress = IProtocolDirectory(directoryAddress)
            .getMembershipFactory();
        membershipPlan memory _membershipPlan = IMembershipFactory(
            IMembershipFactoryAddress
        ).getMembershipPlan(_membership.membershipId);

        if (!_membershipPlan.active) {
            revert(Errors.MS_INACTIVE);
        }

        if (msg.value != _membershipPlan.costOfMembership) {
            revert(Errors.MS_NEED_MORE_DOUGH);
        }

        _membership.membershipEnded =
            block.timestamp +
            _membershipPlan.membershipDuration;
        _membership.payedAmount = msg.value;
        _membership.updatesPerYear =
            _membership.updatesPerYear +
            _membershipPlan.updatesPerYear;

        IMembershipFactory(IMembershipFactoryAddress).transferToPool{
            value: msg.value
        }();
        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );
    }

    /**
     * @dev renewmembershipNFT - Function to renew membership for users that have NFTs
     * @param _contractAddress address of nft to approve renewing
     * @param _NFTType string type of NFT i.e. ERC20 | ERC1155 | ERC721
     * @param tokenId uint256 tokenId being protected
     * @param _uid string identifier of the user renewing membership
     *
     */
    function renewMembershipNFT(
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        string memory _uid
    ) external payable nonReentrant {
        IBlacklist(IProtocolDirectory(directoryAddress).getBlacklistContract())
            .checkIfAddressIsBlacklisted(msg.sender);
        address IMemberAddress = IProtocolDirectory(directoryAddress)
            .getMemberContract();
        IMember(IProtocolDirectory(directoryAddress).getMemberContract())
            .checkUIDofSender(_uid, msg.sender);
        address IMembershipFactoryAddress = IProtocolDirectory(directoryAddress)
            .getMembershipFactory();
        IMember(IMemberAddress).checkIfWalletHasNFT(
            _contractAddress,
            _NFTType,
            tokenId,
            msg.sender
        );
        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];
        membershipPlan memory _membershipPlan = IMembershipFactory(
            IMembershipFactoryAddress
        ).getMembershipPlan(_membership.membershipId);

        if (!_membershipPlan.active) {
            revert(Errors.MS_INACTIVE);
        }

        if (msg.value != _membershipPlan.costOfMembership) {
            revert(Errors.MS_NEED_MORE_DOUGH);
        }

        _membership.membershipEnded =
            block.timestamp +
            _membershipPlan.membershipDuration;
        _membership.payedAmount = msg.value;
        _membership.updatesPerYear =
            _membership.updatesPerYear +
            _membershipPlan.updatesPerYear;

        IMembershipFactory(IMembershipFactoryAddress).transferToPool{
            value: msg.value
        }();

        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );
    }

    /**
     * @dev Function to top up updates
     * @param _uid string identifier of the user across the dApp
     *
     */
    function topUpUpdates(string memory _uid) external payable nonReentrant {
        IBlacklist(IProtocolDirectory(directoryAddress).getBlacklistContract())
            .checkIfAddressIsBlacklisted(msg.sender);
        address IMembershipFactoryAddress = IProtocolDirectory(directoryAddress)
            .getMembershipFactory();
        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];
        IMember(IProtocolDirectory(directoryAddress).getMemberContract())
            .checkUIDofSender(_uid, msg.sender);
        uint256 _updateCost = IMembershipFactory(IMembershipFactoryAddress)
            .getUpdatesPerYearCost();

        if (msg.value < _updateCost) {
            revert(Errors.MS_NEED_MORE_DOUGH);
        }

        _membership.updatesPerYear = _membership.updatesPerYear + 1;

        IMembershipFactory(IMembershipFactoryAddress).transferToPool{
            value: msg.value
        }();

        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );
    }

    /**
     * @notice changeMembershipPlan
     * Ability to change membership plan for a member given a membership ID and member UID.
     * It is a payable function given the membership cost for the membership plan.
     *
     * @param membershipId uint256 id of membership plan changing to
     * @param _uid string identifier of the user
     */
    function changeMembershipPlan(uint256 membershipId, string memory _uid)
        external
        payable
        nonReentrant
    {
        IBlacklist(IProtocolDirectory(directoryAddress).getBlacklistContract())
            .checkIfAddressIsBlacklisted(msg.sender);
        address IMembershipFactoryAddress = IProtocolDirectory(directoryAddress)
            .getMembershipFactory();
        membershipPlan memory _membershipPlan = IMembershipFactory(
            IMembershipFactoryAddress
        ).getMembershipPlan(membershipId);
        IMember(IProtocolDirectory(directoryAddress).getMemberContract())
            .checkUIDofSender(_uid, msg.sender);
        if (msg.value != _membershipPlan.costOfMembership) {
            revert(Errors.MS_NEED_MORE_DOUGH);
        }

        if (!_membershipPlan.active) {
            revert(Errors.MS_INACTIVE);
        }

        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];

        _membership.membershipId = _membershipPlan.membershipId;
        _membership.membershipEnded =
            block.timestamp +
            _membershipPlan.membershipDuration;
        _membership.updatesPerYear =
            _membership.updatesPerYear +
            _membershipPlan.updatesPerYear;
        _membership.payedAmount = msg.value;

        IMembershipFactory(IMembershipFactoryAddress).setUserForMembershipPlan(
            _uid,
            _membershipPlan.membershipId
        );

        IMembershipFactory(IMembershipFactoryAddress).transferToPool{
            value: msg.value
        }();
        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );
    }

    /**
     * @notice changeMembershipPlanNFT - Function to change membership plan to an NFT based plan
     * @param membershipId uint256 id of the membershipPlan changing to
     * @param _contractAddress address of the NFT granting the membership
     * @param _NFTType string type of NFT i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId of the nft to verify ownership
     * @param _uid string identifier of the user across the dApp
     *
     */
    function changeMembershipPlanNFT(
        uint256 membershipId,
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        string memory _uid
    ) external payable {
        IBlacklist(IProtocolDirectory(directoryAddress).getBlacklistContract())
            .checkIfAddressIsBlacklisted(msg.sender);
        address IMemberAddress = IProtocolDirectory(directoryAddress)
            .getMemberContract();
        address IMembershipFactoryAddress = IProtocolDirectory(directoryAddress)
            .getMembershipFactory();
        IMember(IProtocolDirectory(directoryAddress).getMemberContract())
            .checkUIDofSender(_uid, msg.sender);
        IMember(IMemberAddress).checkIfWalletHasNFT(
            _contractAddress,
            _NFTType,
            tokenId,
            msg.sender
        );
        membershipPlan memory _membershipPlan = IMembershipFactory(
            IMembershipFactoryAddress
        ).getMembershipPlan(membershipId);
        if (msg.value != _membershipPlan.costOfMembership) {
            revert(Errors.MS_NEED_MORE_DOUGH);
        }

        if (!_membershipPlan.active) {
            revert(Errors.MS_INACTIVE);
        }

        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];

        _membership.membershipId = _membershipPlan.membershipId;
        _membership.membershipEnded =
            block.timestamp +
            _membershipPlan.membershipDuration;
        _membership.updatesPerYear =
            _membership.updatesPerYear +
            _membershipPlan.updatesPerYear;
        _membership.payedAmount = msg.value;

        IMembershipFactory(IMembershipFactoryAddress).setUserForMembershipPlan(
            _uid,
            _membershipPlan.membershipId
        );

        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );

        IMembershipFactory(IMembershipFactoryAddress).transferToPool{
            value: msg.value
        }();
    }

    /**
     * @notice redeemUpdate
     * @param _uid string identifier of the user across the dApp
     *
     * Function to claim that a membership has been updated
     */
    function redeemUpdate(string memory _uid) external {
        checkIfMembershipActive(_uid);
        MembershipStruct storage _membership = membershipInfoOfAddress[_uid];
        _membership.updatesPerYear = _membership.updatesPerYear - 1;

        emit membershipUpdated(
            address(this),
            _membership.user,
            _membership.uid,
            _membership.membershipStarted,
            _membership.membershipEnded,
            _membership.membershipId,
            _membership.updatesPerYear,
            _membership.nftCollection
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IProtocolDirectory.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IMembership.sol";
import "./interfaces/IMembershipFactory.sol";
import "./interfaces/IBlacklist.sol";

import "./libraries/Errors.sol";
import "./libraries/TokenActions.sol";

import "./structs/MemberStruct.sol";
import "./structs/BackupApprovalStruct.sol";
import "./structs/MembershipStruct.sol";

/**
 * @title Member Contract
 * @notice This contract contains logic for interacting with the
 * ecosystem and verifying ownership as well as the panic button
 * functionality and backup information (BackupPlan)
 *
 */

contract Member is
    IMember,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @notice memberCreated Event when creating member
     * @param uid string of dApp identifier for a user
     * @param dateCreated timestamp of event occurence
     *
     */
    event memberCreated(string uid, uint256 dateCreated);

    /**
     * @notice Event when updating primary wallet
     * @param uid string string of dApp identifier for a user
     * @param dateCreated uint256 timestamap of event occuring
     * @param wallets address[] list of wallets for the user
     * @param primaryWallet uint256 primary wallet for assets
     *
     */
    event walletUpdated(
        string uid,
        uint256 dateCreated,
        address[] backUpWallets,
        address[] wallets,
        uint256 primaryWallet
    );

    /// @notice Mapping to return member when uid is passed
    mapping(string => member) public members;

    /// @notice Variable to store all member information
    member[] public allMembers;

    /// @notice UserMembershipAddress mapping for getting Membership contracts by user
    mapping(string => address) private UserMembershipAddress;

    /// @notice Storing ApprovalId for different approvals stored
    uint256 private _approvalId;

    /// @notice mapping for token backup Approvals for specific UID
    mapping(string => BackUpApprovals[]) private MemberApprovals;

    /**
     * @notice Event for Querying Approvals
     *
     * @param uid string of dApp identifier for a user
     * @param approvedWallet address of the wallet owning the asset
     * @param backupaddress address[] list of addresses containing assets
     * @param tokenId uint256 tokenId of asset being backed up
     * @param tokenAddress address contract of the asset being protectd
     * @param tokenType string i.e. ERC20 | ERC1155 | ERC721
     * @param tokensAllocated uint256 number of tokens to be protected
     * @param dateApproved uint256 timestamp of event happening
     * @param claimed bool status of the backupApproval
     * @param approvalId uint256 id of the approval being acted on
     * @param claimedWallet address of receipient of assets
     *
     *
     */
    event BackUpApprovalsEvent(
        string uid,
        address approvedWallet,
        address[] backupaddress,
        uint256 tokenId,
        address tokenAddress,
        string tokenType,
        uint256 tokensAllocated,
        uint256 dateApproved,
        bool claimed,
        uint256 approvalId,
        address claimedWallet
    );

    /// @dev address of the ProtocolDirectory
    address public directoryContract;

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of protocol directory contract
     */
    function initialize(address _directoryContract) external initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();
        _approvalId = 0;
        directoryContract = _directoryContract;
    }

    /**
     * @notice Function to check if wallet exists in the UID
     * @param _uid string of dApp identifier for a user
     * @param _user address of the user checking exists
     * Fails if not owner uid and user address do not return a wallet
     *
     */
    function checkUIDofSender(string memory _uid, address _user) public view {
        address[] memory wallets = members[_uid].wallets;
        bool walletExists = false;
        for (uint256 i = 0; i < wallets.length; i++) {
            if (wallets[i] == _user) {
                walletExists = true;
            }
        }

        if (walletExists == false) {
            revert(Errors.M_NOT_OWNER);
        }
    }

    /**
     * @dev checkIfUIDExists
     * Check if user exists for specific wallet address already internal function
     * @param _walletAddress wallet address of the user
     * @return _exists - A boolean if user exists or not
     *
     */
    function checkIfUIDExists(address _walletAddress)
        public
        view
        returns (bool _exists)
    {
        address IBlacklistUsersAddress = IProtocolDirectory(directoryContract)
            .getBlacklistContract();
        IBlacklist(IBlacklistUsersAddress).checkIfAddressIsBlacklisted(
            _walletAddress
        );
        for (uint256 i = 0; i < allMembers.length; i++) {
            address[] memory _wallets = allMembers[i].wallets;
            if (_wallets.length != 0) {
                for (uint256 j = 0; j < _wallets.length; j++) {
                    if (_wallets[j] == _walletAddress) {
                        _exists = true;
                    }
                }
            }
        }
    }

    /**
     * @notice checkIfWalletHasNFT
     * verify if the user has specific nft 1155 or 721
     * @param _contractAddress address of asset contract
     * @param _NFTType string i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId checking for ownership
     * @param userAddress address address to verify ownership of
     * Fails if not owner
     */
    function checkIfWalletHasNFT(
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        address userAddress
    ) external view {
        // check if wallet has nft
        bool status = false;
        if (
            keccak256(abi.encodePacked((_NFTType))) ==
            keccak256(abi.encodePacked(("ERC721")))
        ) {
            if (IERC721(_contractAddress).ownerOf(tokenId) == userAddress) {
                status = true;
            } else if (
                IERC721Upgradeable(_contractAddress).ownerOf(tokenId) ==
                userAddress
            ) {
                status = true;
            }
        }

        if (
            keccak256(abi.encodePacked((_NFTType))) ==
            keccak256(abi.encodePacked(("ERC1155")))
        ) {
            if (
                IERC1155(_contractAddress).balanceOf(userAddress, tokenId) != 0
            ) {
                status = true;
            } else if (
                IERC1155Upgradeable(_contractAddress).balanceOf(
                    userAddress,
                    tokenId
                ) != 0
            ) {
                status = true;
            }
        }

        if (status == false) {
            revert(Errors.M_NOT_HOLDER);
        }
    }

    /**
     * @dev createMember
     * @param  uid centrally stored id for user
     * @param _walletAddress walletAddress to add wallet and check blacklist
     *
     * Allows to create a member onChain with a unique UID passed.
     * Will revert if the _walletAddress passed in is blacklisted
     *
     */
    function createMember(string memory uid, address _walletAddress) public {
        address IBlacklistUsersAddress = IProtocolDirectory(directoryContract)
            .getBlacklistContract();
        IBlacklist(IBlacklistUsersAddress).checkIfAddressIsBlacklisted(
            _walletAddress
        );
        if (
            (keccak256(abi.encodePacked((members[uid].uid))) !=
                keccak256(abi.encodePacked((uid))) &&
                (checkIfUIDExists(_walletAddress) == false))
        ) {
            if (bytes(uid).length == 0) {
                revert(Errors.M_EMPTY_UID);
            }
            address[] memory _wallets;
            member memory _member = member(
                uid,
                block.timestamp,
                _wallets,
                _wallets,
                0
            );
            members[uid] = _member;
            allMembers.push(_member);
            addWallet(uid, _walletAddress, true);
            emit memberCreated(_member.uid, _member.dateCreated);
        } else {
            revert(Errors.M_USER_EXISTS);
        }
    }

    /**
     * @dev getMember
     * @param uid string for centrally located identifier
     * Allows to get member information stored onChain with a unique UID passed.
     * @return member struct for a given uid
     *
     */
    function getMember(string memory uid)
        public
        view
        override
        returns (member memory)
    {
        member memory currentMember = members[uid];
        if (currentMember.dateCreated == 0) {
            revert(Errors.M_USER_DNE);
        }
        return currentMember;
    }

    /**
     * @dev getAllMembers
     * Allows to get all member information stored onChain
     * @return allMembers a list of member structs
     *
     */
    function getAllMembers() external view returns (member[] memory) {
        return allMembers;
    }

    /**
     * @dev addWallet - Allows to add Wallet to the user
     * @param uid string for dApp user identifier
     * @param _wallet address wallet being added for given user
     * @param _primary bool whether or not this new wallet is the primary wallet
     *
     *
     */
    function addWallet(
        string memory uid,
        address _wallet,
        bool _primary
    ) public {
        member storage _member = members[uid];
        _member.wallets.push(_wallet);
        if (_primary) {
            _member.primaryWallet = _member.wallets.length - 1;
        }

        for (uint256 i = 0; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (
                keccak256(abi.encodePacked((member_.uid))) ==
                keccak256(abi.encodePacked((uid)))
            ) {
                member_.wallets.push(_wallet);
                if (_primary) {
                    member_.primaryWallet = member_.wallets.length - 1;
                }
            }
        }

        emit walletUpdated(
            _member.uid,
            _member.dateCreated,
            _member.backUpWallets,
            _member.wallets,
            _member.primaryWallet
        );
    }

    /**
     * @dev addBackUpWallet - Allows to add backUp Wallets to the user
     * @param uid string for dApp user identifier
     * @param _wallets addresses of wallets being added for given user
     *
     *
     */
    function addBackupWallet(
        string calldata uid,
        address[] memory _wallets,
        address _user
    ) public {
        if ((checkIfUIDExists(_user) == false)) {
            createMember(uid, _user);
        }
        member storage _member = members[uid];
        if (_member.wallets.length == 0) {
            revert(Errors.M_USER_MUST_WALLET);
        }
        for (uint256 i = 0; i < _wallets.length; i++) {
            _member.backUpWallets.push(_wallets[i]);
        }

        for (uint256 i = 0; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (
                keccak256(abi.encodePacked((member_.uid))) ==
                keccak256(abi.encodePacked((uid)))
            ) {
                for (uint256 j = 0; j < _wallets.length; j++) {
                    member_.backUpWallets.push(_wallets[j]);
                }
            }
        }
        emit walletUpdated(
            _member.uid,
            _member.dateCreated,
            _member.backUpWallets,
            _member.wallets,
            _member.primaryWallet
        );
    }

    /**
     * @dev getBackupWallets - Returns backup Wallets for the specific UID
     * @param uid string for dApp user identifier
     *
     */
    function getBackupWallets(string calldata uid)
        external
        view
        returns (address[] memory)
    {
        return members[uid].backUpWallets;
    }

    /**
     * @dev deleteWallet - Allows to delete  wallets of a specific user
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function deleteWallet(string calldata uid, uint256 _walletIndex) external {
        checkUIDofSender(uid, msg.sender);
        member storage _member = members[uid];
        if (_walletIndex == _member.primaryWallet) {
            revert(Errors.M_PRIM_WALLET);
        }
        delete members[uid].wallets[_walletIndex];
        address[] storage wallets = members[uid].wallets;
        for (uint256 i = _walletIndex; i < wallets.length - 1; i++) {
            wallets[i] = wallets[i + 1];
        }

        if (members[uid].primaryWallet >= _walletIndex) {
            members[uid].primaryWallet--;
        }
        wallets.pop();

        for (uint256 i = 0; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (
                keccak256(abi.encodePacked((member_.uid))) ==
                keccak256(abi.encodePacked((uid)))
            ) {
                address[] storage wallets_ = member_.wallets;
                for (uint256 j = _walletIndex; j < wallets_.length - 1; j++) {
                    wallets_[j] = wallets_[j + 1];
                }
                wallets_.pop();
                if (member_.primaryWallet >= _walletIndex) {
                    member_.primaryWallet--;
                }
            }
        }
    }

    /**
     * @dev setPrimaryWallet
     * Allows to set a specific wallet as the primary wallet
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function setPrimaryWallet(string calldata uid, uint256 _walletIndex)
        external
        override
    {
        checkUIDofSender(uid, msg.sender);
        if (_walletIndex == members[uid].primaryWallet) {
            revert(Errors.M_ALREADY_PRIM);
        }
        members[uid].primaryWallet = _walletIndex;
        for (uint256 i = 0; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (
                keccak256(abi.encodePacked((member_.uid))) ==
                keccak256(abi.encodePacked((uid)))
            ) {
                member_.primaryWallet = _walletIndex;
            }
        }
    }

    /**
     * @dev getWallets
     * Allows to get all wallets of the user
     * @param uid string for dApp user identifier
     * @return address[] list of wallets
     *
     */
    function getWallets(string calldata uid)
        external
        view
        override
        returns (address[] memory)
    {
        return members[uid].wallets;
    }

    /**
     * @dev getPrimaryWallets
     * Allows to get primary wallet of the user
     * @param uid string for dApp user identifier
     * @return address of the primary wallet per user
     *
     */
    function getPrimaryWallet(string memory uid)
        external
        view
        override
        returns (address)
    {
        return members[uid].wallets[members[uid].primaryWallet];
    }

    /**
     * @dev getUID
     * Allows user to pass walletAddress and return UID
     * @param _walletAddress get the UID of the user's if their wallet address is present
     * @return memberuid string of the ID used in the dApp to identify they user
     *
     */
    function getUID(address _walletAddress)
        external
        view
        override
        returns (string memory memberuid)
    {
        for (uint256 i = 0; i < allMembers.length; i++) {
            address[] memory _wallets = allMembers[i].wallets;
            if (_wallets.length != 0) {
                for (uint256 j = 0; j < _wallets.length; j++) {
                    if (_wallets[j] == _walletAddress) {
                        memberuid = allMembers[i].uid;
                    }
                }
            }
        }
        if (bytes(memberuid).length == 0) {
            revert(Errors.M_UID_DNE);
        }
        return memberuid;
    }

    /**
     * @dev storeBackupAssetsApprovals - Function to store All Types Approvals by the user for backup
     *
     * @param _contractAddress address[] Ordered list of contract addresses for assets
     * @param _tokenIds uint256[] Ordered list of tokenIds associated with contract addresses
     * @param _backUpWallets address[] Ordered list of wallet addresses to backup assets
     * @param _tokenAmount uint256[] Ordered list of amounts per asset contract and token id to protext
     * @param _tokenTypes string[] Ordered list of strings i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string for dApp user identifier
     * @param _userAddress address of the user
     * @param _super bool true if function is being called from a parent function. false if directly
     *
     */
    function storeBackupAssetsApprovals(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID,
        address _userAddress,
        bool _super
    ) public {
        if (
            _tokenIds.length != _contractAddress.length ||
            _tokenAmount.length != _tokenTypes.length
        ) {
            revert(Errors.M_DIFF_LENGTHS);
        }

        if (_super == false) {
            checkUIDofSender(_memberUID, msg.sender);
        }

        if ((checkIfUIDExists(_userAddress) == false)) {
            createMember(_memberUID, _userAddress);
        }
        member memory _member = getMember(_memberUID);

        checkUserHasMembership(_memberUID, _userAddress);
        addBackupWallet(_memberUID, _backUpWallets, _userAddress);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address contractAddress = _contractAddress[i];
            uint256 tokenId_ = _tokenIds[i];
            string memory tokenType = _tokenTypes[i];
            uint256 tokenAmount = _tokenAmount[i];

            TokenActions.checkAssetContract(contractAddress, tokenType);
            Token memory _token = Token(
                tokenId_,
                contractAddress,
                tokenType,
                tokenAmount
            );

            _storeAssets(
                _memberUID,
                _member,
                _userAddress,
                _backUpWallets,
                _token
            );
        }
        IMembership(UserMembershipAddress[_memberUID]).redeemUpdate(_memberUID);
    }

    /**
     * @dev _storeAssets - Internal function to store assets approvals for backup
     * @param uid string identifier of user across dApp
     * @param _member member struct of user storing assets for
     * @param user address of the user of the dApp
     * @param _backUpWallet address[] list of wallets protected
     * @param _token Token struct containing token information
     *
     */
    function _storeAssets(
        string calldata uid,
        member memory _member,
        address user,
        address[] calldata _backUpWallet,
        Token memory _token
    ) internal {
        uint256 _dateApproved = block.timestamp;

        BackUpApprovals memory approval = BackUpApprovals(
            _member,
            user,
            _backUpWallet,
            _token,
            _dateApproved,
            false,
            ++_approvalId
        );

        MemberApprovals[uid].push(approval);
        emit BackUpApprovalsEvent(
            _member.uid,
            user,
            _backUpWallet,
            _token.tokenId,
            _token.tokenAddress,
            _token.tokenType,
            _token.tokensAllocated,
            _dateApproved,
            false,
            _approvalId,
            address(0)
        );
    }

    /**
     * @dev executePanic - Public function to transfer assets from one user to another
     * @param _backUpWallet wallet to panic send assets to
     * @param _memberUID uid of the user's assets being moved
     *
     */
    function executePanic(address _backUpWallet, string memory _memberUID)
        external
    {
        address IBlacklistUsersAddress = IProtocolDirectory(directoryContract)
            .getBlacklistContract();
        if (MemberApprovals[_memberUID].length <= 0) {
            revert(Errors.M_BACKUP_FIRST);
        }

        IBlacklist(IBlacklistUsersAddress).checkIfAddressIsBlacklisted(
            _backUpWallet
        );
        _panic(_memberUID, _backUpWallet);
    }

    /**
     * @dev _checkBackUpExists - Internal function that checks backup approvals if the backup Wallet Exists
     * @param _approvals BackUpApprovals struct with backup information
     * @param _backUpWallet wallet to verify is inside of approval
     *
     */
    function _checkBackUpExists(
        BackUpApprovals memory _approvals,
        address _backUpWallet
    ) internal pure {
        bool backUpExists = false;
        for (uint256 j = 0; j < _approvals.backUpWallet.length; j++) {
            if (_approvals.backUpWallet[j] == _backUpWallet) {
                backUpExists = true;
            }
        }
        if (!backUpExists) {
            revert(Errors.M_INVALID_BACKUP);
        }
    }

    /**
     * @dev _panic - Private Function to test panic functionality in order to execute and transfer all assets from one user to another
     * @param uid string of identifier for user in dApp
     * @param _backUpWallet address where to send assets to
     *
     */
    function _panic(string memory uid, address _backUpWallet)
        internal
        nonReentrant
    {
        BackUpApprovals[] storage _approvals = MemberApprovals[uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            if (_approvals[i].claimed == false) {
                _checkBackUpExists(_approvals[i], _backUpWallet);
                if (
                    keccak256(
                        abi.encodePacked((_approvals[i].token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC20")))
                ) {
                    IERC20 ERC20 = IERC20(_approvals[i].token.tokenAddress);

                    uint256 tokenAllowance = ERC20.allowance(
                        _approvals[i].approvedWallet,
                        address(this)
                    );
                    uint256 tokenBalance = ERC20.balanceOf(
                        _approvals[i].approvedWallet
                    );

                    _approvals[i].claimed = true;

                    if (tokenBalance <= tokenAllowance) {
                        if (tokenBalance != 0) {
                            bool sent = ERC20.transferFrom(
                                _approvals[i].approvedWallet,
                                _backUpWallet,
                                tokenBalance
                            );
                        }
                    } else {
                        if (tokenBalance != 0) {
                            bool sent = ERC20.transferFrom(
                                _approvals[i].approvedWallet,
                                _backUpWallet,
                                tokenAllowance
                            );
                        }
                    }

                    emit BackUpApprovalsEvent(
                        _approvals[i].Member.uid,
                        _approvals[i].approvedWallet,
                        _approvals[i].backUpWallet,
                        _approvals[i].token.tokenId,
                        _approvals[i].token.tokenAddress,
                        _approvals[i].token.tokenType,
                        _approvals[i].token.tokensAllocated,
                        _approvals[i].dateApproved,
                        _approvals[i].claimed,
                        _approvals[i].approvalId,
                        _backUpWallet
                    );
                }
                if (
                    keccak256(
                        abi.encodePacked((_approvals[i].token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC721")))
                ) {
                    IERC721 ERC721 = IERC721(_approvals[i].token.tokenAddress);

                    address _tokenAddress = ERC721.ownerOf(
                        _approvals[i].token.tokenId
                    );

                    if (_tokenAddress == _approvals[i].approvedWallet) {
                        ERC721.safeTransferFrom(
                            _approvals[i].approvedWallet,
                            _backUpWallet,
                            _approvals[i].token.tokenId
                        );
                    }

                    _approvals[i].claimed = true;
                    emit BackUpApprovalsEvent(
                        _approvals[i].Member.uid,
                        _approvals[i].approvedWallet,
                        _approvals[i].backUpWallet,
                        _approvals[i].token.tokenId,
                        _approvals[i].token.tokenAddress,
                        _approvals[i].token.tokenType,
                        _approvals[i].token.tokensAllocated,
                        _approvals[i].dateApproved,
                        _approvals[i].claimed,
                        _approvals[i].approvalId,
                        _backUpWallet
                    );
                }
                if (
                    keccak256(
                        abi.encodePacked((_approvals[i].token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC1155")))
                ) {
                    IERC1155 ERC1155 = IERC1155(
                        _approvals[i].token.tokenAddress
                    );

                    uint256 _balance = ERC1155.balanceOf(
                        _approvals[i].approvedWallet,
                        _approvals[i].token.tokenId
                    );
                    bytes memory data;

                    if (_balance <= _approvals[i].token.tokensAllocated) {
                        ERC1155.safeTransferFrom(
                            _approvals[i].approvedWallet,
                            _backUpWallet,
                            _approvals[i].token.tokenId,
                            _balance,
                            data
                        );
                    } else {
                        ERC1155.safeTransferFrom(
                            _approvals[i].approvedWallet,
                            _backUpWallet,
                            _approvals[i].token.tokenId,
                            _approvals[i].token.tokensAllocated,
                            data
                        );
                    }

                    _approvals[i].claimed = true;
                    emit BackUpApprovalsEvent(
                        _approvals[i].Member.uid,
                        _approvals[i].approvedWallet,
                        _approvals[i].backUpWallet,
                        _approvals[i].token.tokenId,
                        _approvals[i].token.tokenAddress,
                        _approvals[i].token.tokenType,
                        _approvals[i].token.tokensAllocated,
                        _approvals[i].dateApproved,
                        _approvals[i].claimed,
                        _approvals[i].approvalId,
                        _backUpWallet
                    );
                }
            }
        }
    }

    /**
     * @dev getBackupApprovals - function to return all backupapprovals for a specific UID
     * @param uid string of identifier for user in dApp
     * @return BackUpApprovals[] list of BackUpApprovals struct
     *
     */
    function getBackupApprovals(string memory uid)
        external
        view
        returns (BackUpApprovals[] memory)
    {
        return MemberApprovals[uid];
    }

    /**
     * @dev editBackup - Function to edit individual backup approvals
     * @param approvalId_ uint256 id to lookup Approval and edit
     * @param _contractAddress address contractAddress of asset to save
     * @param _tokenIds uint256 tokenId of asset
     * @param _tokenAmount uint256 amount of specific token
     * @param _tokenType string type of the token i.e. ERC20 | ERC721 | ERC1155
     * @param _uid string of identifier for user in dApp
     * @param _user address of the user of the dApp
     *
     */
    function editBackUp(
        uint256 approvalId_,
        address _contractAddress,
        uint256 _tokenIds,
        uint256 _tokenAmount,
        string calldata _tokenType,
        string memory _uid,
        address _user
    ) external {
        member memory _member = getMember(_uid);
        checkUserHasMembership(_uid, _user);

        BackUpApprovals[] storage _approvals = MemberApprovals[_member.uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            if (_approvals[i].approvalId == approvalId_) {
                _approvals[i].token.tokenAddress = _contractAddress;
                _approvals[i].token.tokenId = _tokenIds;
                _approvals[i].token.tokensAllocated = _tokenAmount;
                _approvals[i].token.tokenType = _tokenType;
            }
        }
        IMembership(UserMembershipAddress[_uid]).redeemUpdate(_uid);
    }

    /**
     * @dev editAllBackUp - Function to delete and add new approvals for backup
     * @param _contractAddress address[] Ordered list of addresses for asset contracts
     * @param _tokenIds uint256[] Ordered list of tokenIds to backup
     * @param _backUpWallets address[] Ordered list of wallets that can be backups
     * @param _tokenAmount uint256[] Ordered list of amounts of tokens to backup
     * @param _tokenTypes string[] Ordered list of string tokenTypes i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string of identifier for user in dApp
     * @param _user address of the user of the dApp
     *
     *
     */
    function editAllBackUp(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID,
        address _user
    ) external {
        checkUserHasMembership(_memberUID, _user);
        deleteAllBackUp(_memberUID);
        storeBackupAssetsApprovals(
            _contractAddress,
            _tokenIds,
            _backUpWallets,
            _tokenAmount,
            _tokenTypes,
            _memberUID,
            _user,
            true
        );
    }

    /**
     * @dev deleteAllBackUp - Function to delete all backup approvals
     * @param _uid string of identifier for user in dApp
     *
     */
    function deleteAllBackUp(string memory _uid) public {
        member memory _member = getMember(_uid);
        delete MemberApprovals[_member.uid];
    }

    /**
     * @notice checkUserHasMembership - Function to check if user has membership
     * @param _uid string of identifier for user in dApp
     * @param _user address of the user of the dApp
     *
     */
    function checkUserHasMembership(string memory _uid, address _user)
        public
        view
    {
        IBlacklist(IProtocolDirectory(directoryContract).getBlacklistContract())
            .checkIfAddressIsBlacklisted(_user);
        IMembership _membership = IMembership(UserMembershipAddress[_uid]);
        bool _MembershipActive = _membership.checkIfMembershipActive(_uid);
        if (_MembershipActive == false) {
            revert(Errors.M_NOT_MEMBER);
        } else {
            MembershipStruct memory Membership = IMembership(
                UserMembershipAddress[_uid]
            ).getMembership(_uid);
            if (Membership.updatesPerYear <= 0) {
                revert(Errors.M_NEED_TOP);
            }
        }
    }

    /**
     * @dev Function set MembershipAddress for a Uid
     * @param _uid string of identifier for user in dApp
     * @param _Membership address of the user's associated membership contract
     *
     */
    function setIMembershipAddress(string memory _uid, address _Membership)
        external
    {
        address factoryAddress = IProtocolDirectory(directoryContract)
            .getMembershipFactory();
        if (factoryAddress != msg.sender) {
            revert(Errors.M_INVALID_ADDRESS);
        }
        UserMembershipAddress[_uid] = _Membership;
    }

    /**
     * @dev Function to get MembershipAddress for a given Uid
     * @param _uid string of identifier for user in dApp
     *
     */
    function getIMembershipAddress(string memory _uid)
        external
        view
        returns (address)
    {
        return UserMembershipAddress[_uid];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

import "./structs/ApprovalsStruct.sol";
import "./interfaces/IAssetStoreFactory.sol";
import "./interfaces/IAssetStore.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IProtocolDirectory.sol";

/**
 * @title RelayerContract
 *
 * Logic for communicatiing with the relayer and contract state
 *
 */

contract ChainlinkOperations is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ChainlinkClient
{
    /// @dev ProtocolDirectory location
    address public directoryContract;

    /// @dev allows us to use Chainlink methods for requesting data
    using Chainlink for Chainlink.Request;

    /// @dev job ID that the node provider sets up
    bytes32 private jobId;

    /// @dev amount in link to pay oracle for data
    uint256 private constant ORACLE_PAYMENT = 0;

    /// @dev URL of our API that will be requested
    string private WEBACY_API_URL;

    /// @dev What field(s) in the JSON response we want
    string private PATH;

    /// @dev LINK token
    IERC20 public LINK_TOKEN;

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract - address of the ProtocolDirectory contract
     * @param _webacyUrl - URL of our API that will be requested
     * @param _linkToken - address of the LINK token
     * @param _oracle - address of the oracle
     * @param _jobId - job ID that the node provider sets up
     */
    function initialize(
        address _directoryContract,
        string calldata _webacyUrl,
        string calldata _path,
        address _linkToken,
        address _oracle,
        bytes32 _jobId
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();
        directoryContract = _directoryContract;
        WEBACY_API_URL = _webacyUrl;
        PATH = _path;
        setChainlinkToken(_linkToken);
        LINK_TOKEN = IERC20(_linkToken);
        setChainlinkOracle(_oracle);
        jobId = _jobId;
    }

    /**
     * @dev setWebacyUrl updates the API URL we're requesting
     * @param _webacyUrl - new url
     */
    function setWebacyUrl(string calldata _webacyUrl) external onlyOwner {
        WEBACY_API_URL = _webacyUrl;
    }

    /**
     * @dev setPath updates the path to fetch from response. If an empty string then the entire response is returned
     * @param _path - new path
     */
    function setPath(string calldata _path) external onlyOwner {
        PATH = _path;
    }

    /**
     * @dev setOracle updates oracle address in the event we're changing node providers
     * @param _addr - new oracle address
     */
    function setOracle(address _addr) external onlyOwner {
        setChainlinkOracle(_addr);
    }

    /**
     * @dev setLinkToken updates linkTokenAddress
     * @param _addr - new token address
     */
    function setLinkToken(address _addr) external onlyOwner {
        setChainlinkToken(_addr);
        LINK_TOKEN = IERC20(_addr);
    }

    /**
     * @dev setJobId
     * @param _id - id of the job
     */
    function setJobId(bytes32 _id) external onlyOwner {
        jobId = _id;
    }

    /**
     * @dev withdrawLInk - withdraws LINK from the contract
     */
    function withdrawLink() external onlyOwner {
        bool sent = LINK_TOKEN.transfer(
            msg.sender,
            LINK_TOKEN.balanceOf(address(this))
        );
        require(sent, "Transfer Failed");
    }

    /**
     * @dev requestBytes - this is the "main" function that calls our API
     */
    function requestBytes() public {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillArray.selector
        );
        req.add("get", WEBACY_API_URL);
        // if PATH is not an empty string add it to the request
        if (bytes(PATH).length > 0) {
            req.add("path", PATH);
        }
        sendOperatorRequest(req, ORACLE_PAYMENT);
    }

    /// @dev this event indicated the API request has been relayed successfully
    event RequestFulfilled(bytes32 indexed requestId);

    /**
     * @dev fulfillArray is our callback function - i.e., what to do with the data when it is recieved by our conract
     * @dev we're turning the bytes into an address and then setting the approvals active for that address
     * @param requestId - id of the request
     * @param _arrayOfBytes - data returned from the API
     */
    function fulfillArray(bytes32 requestId, bytes[] memory _arrayOfBytes)
        public
        recordChainlinkFulfillment(requestId)
    {
        for (uint8 i = 0; i < _arrayOfBytes.length; i++) {
            _setApprovalActiveForUID(string(_arrayOfBytes[i]));
        }

        emit RequestFulfilled(requestId);
    }

    /**
     * @dev setApprovalActiveForUID - allows beneficiaries to claim on behalf of a given uid
     * @param _uid - uid to activate
     */
    function setApprovalActiveForUID(string memory _uid) external onlyOwner {
        _setApprovalActiveForUID(_uid);
    }

    /**
     * @dev _setApprovalActiveForUID - internal version called by fulfillArray
     * @param _uid - uid to activate
     */
    function _setApprovalActiveForUID(string memory _uid) internal {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_uid);
        IAssetStore(usersAssetStoreAddress).setApprovalActive(_uid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./structs/ApprovalsStruct.sol";
import "./interfaces/IAssetStoreFactory.sol";
import "./interfaces/IAssetStore.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IProtocolDirectory.sol";
import "./libraries/Errors.sol";

/**
 * @title RelayerContract
 *
 * Logic for communicatiing with the relayer and contract state
 *
 */

contract RelayerContract is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @dev address of the relayer account
    address public relayerAddress;

    /// @dev address ProtocolDirectory location
    address public directoryContract;

    /**
     * @notice onlyRelayer
     * modifier to ensure only the relayer account can make changes
     *
     */
    modifier onlyRelayer() {
        if (msg.sender != relayerAddress) {
            revert(Errors.RC_UNAUTHORIZED);
        }
        _;
    }

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of the directory contract
     *
     */
    function initialize(address _directoryContract) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();

        directoryContract = _directoryContract;
    }

    /**
     * @dev Set Approval Active for a Specific UID
     * @param _uid string identifier of a user on the dApp
     * This function is called by the predetermined relayer account
     * to trigger that a user's will claim period is now active
     *
     */
    function setApprovalActiveForUID(string memory _uid) external onlyRelayer {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_uid);
        IAssetStore(usersAssetStoreAddress).setApprovalActive(_uid);
    }

    /**
     * @dev transferUnclaimedAssets
     * @param _userUID string identifier of a user across the dApp
     * Triggered by the relayer once it is too late for the beneficiaries to claim
     *
     */
    function transferUnclaimedAssets(string memory _userUID)
        external
        onlyRelayer
    {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_userUID);

        IAssetStore(usersAssetStoreAddress).transferUnclaimedAssets(_userUID);
    }

    /**
     * @dev setRelayerAddress
     * @param _relayerAddress the new address of the relayerAccount
     * Update the relayerAccount by the owner as needed
     *
     */
    function setRelayerAddress(address _relayerAddress) external onlyOwner {
        relayerAddress = _relayerAddress;
    }

    /**
     * @dev triggerAssetsForCharity
     * since charities cannot claim assets, the relayer will
     * call this function which will allocate assets per the user's
     * will
     * @param _userUID of the user on the dApp
     *
     */
    function triggerAssetsForCharity(string memory _userUID)
        external
        onlyRelayer
    {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_userUID);

        Approvals[] memory userApprovals = IAssetStore(usersAssetStoreAddress)
            .getApprovals(_userUID);

        for (uint256 i = 0; i < userApprovals.length; i++) {
            if (userApprovals[i].beneficiary.isCharity) {
                IAssetStore(usersAssetStoreAddress).sendAssetsToCharity(
                    userApprovals[i].beneficiary.beneficiaryAddress,
                    _userUID
                );
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IProtocolDirectory.sol";

/**
 * @title ProtocolDirectory
 *
 * This contract will serve as the global store of
 * addresses related to the Webacy smart contract suite.
 * With this Directory we can upgrade/change references to contracts
 * and ensure the rest of the suite will be upgraded at the same time.
 *
 *
 */

contract ProtocolDirectory is
    Initializable,
    OwnableUpgradeable,
    IProtocolDirectory
{
    mapping(bytes32 => address) private _addresses;

    bytes32 private constant ASSET_STORE_FACTORY = "ASSET_STORE_FACTORY";
    bytes32 private constant MEMBERSHIP_FACTORY = "MEMBERSHIP_FACTORY";
    bytes32 private constant RELAYER_CONTRACT = "RELAYER_CONTRACT";
    bytes32 private constant MEMBER_CONTRACT = "MEMBER_CONTRACT";
    bytes32 private constant BLACKLIST_CONTRACT = "BLACKLIST_CONTRACT";
    bytes32 private constant WHITELIST_CONTRACT = "WHITELIST_CONTRACT";
    bytes32 private constant TRANSFER_POOL = "TRANSFER_POOL";
    bytes32 private constant CHAINLINK_OPERATIONS_CONTRACT =
        "CHAINLINK_OPERATIONS_CONTRACT";

    /**
     * @notice initialize function
     *
     * Keeping within the design pattern of the rest of the protocol
     * this contract will also be upgradable and initializable
     *
     */
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init();
    }

    /**
     * @notice getAddress
     * @param _contractName string representing the contract you are looking for
     *
     * Use this function to get the locations of the deployed addresses;
     */
    function getAddress(bytes32 _contractName) public view returns (address) {
        return _addresses[_contractName];
    }

    /**
     * @notice setAddress
     * @param _contractName bytes32 name to lookup the contract
     * @param _contractLocation address of the deployment being referenced
     *
     *
     */
    function setAddress(bytes32 _contractName, address _contractLocation)
        public
        onlyOwner
        returns (address)
    {
        _addresses[_contractName] = _contractLocation;
        return _contractLocation;
    }

    //////////////////////////
    //////Get Functions//////
    /////////////////////////

    /**
     * @notice ssetStoreFactory
     * @return address of protocol contract matching ASSET_STORE_FACTORY value
     *
     */
    function getAssetStoreFactory() external view returns (address) {
        return getAddress(ASSET_STORE_FACTORY);
    }

    /**
     * @notice getMembershipFactory
     * @return address of protocol contract matching MEMBERSHIP_FACTORY value
     *
     */
    function getMembershipFactory() external view returns (address) {
        return getAddress(MEMBERSHIP_FACTORY);
    }

    /**
     * @notice getRelayerContract
     * @return address of protocol contract matching RELAYER_CONTRACT value
     *
     */
    function getRelayerContract() external view returns (address) {
        return getAddress(RELAYER_CONTRACT);
    }

    /**
     * @notice getMemberContract
     * @return address of protocol contract matching MEMBER_CONTRACT value
     *
     */
    function getMemberContract() external view returns (address) {
        return getAddress(MEMBER_CONTRACT);
    }

    /**
     * @notice getBlacklistContract
     * @return address of protocol contract matching BLACKLIST_CONTRACT value
     *
     */
    function getBlacklistContract() external view returns (address) {
        return getAddress(BLACKLIST_CONTRACT);
    }

    /**
     * @notice getWhitelistContract
     * @return address of protocol contract matching WHITELIST_CONTRACT value
     *
     */
    function getWhitelistContract() external view returns (address) {
        return getAddress(WHITELIST_CONTRACT);
    }

    /**
     * @notice getTransferPool
     * @return address of protocol contract matching TRANSFER_POOL value
     *
     */
    function getTransferPool() external view returns (address) {
        return getAddress(TRANSFER_POOL);
    }

    /**
     * @notice getChainlinkOperationsContract
     * @return address of protocol contract matching CHAINLINK_OPERATIONS_CON value
     *
     */
    function getChainlinkOperationsContract() external view returns (address) {
        return getAddress(CHAINLINK_OPERATIONS_CONTRACT);
    }

    //////////////////////////
    //////Set Functions//////
    /////////////////////////

    /**
     * @dev setAssetStoreFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setAssetStoreFactory(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(ASSET_STORE_FACTORY, _contractLocation);
    }

    /**
     * @dev setMembershipFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setMembershipFactory(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(MEMBERSHIP_FACTORY, _contractLocation);
    }

    /**
     * @dev setRelayerContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setRelayerContract(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(RELAYER_CONTRACT, _contractLocation);
    }

    /**
     * @dev setMemberContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setMemberContract(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(MEMBER_CONTRACT, _contractLocation);
    }

    /**
     * @dev setBlacklistContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setBlacklistContract(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(BLACKLIST_CONTRACT, _contractLocation);
    }

    /**
     * @dev setWhitelistContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setWhitelistContract(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(WHITELIST_CONTRACT, _contractLocation);
    }

    /**
     * @dev setTransferPool
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setTransferPool(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(TRANSFER_POOL, _contractLocation);
    }

    /**
     * @dev setChainlinkOperationsContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setChainlinkOperationsContract(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(CHAINLINK_OPERATIONS_CONTRACT, _contractLocation);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title WebacyToken
 * Reference erc20 token for testing purposes
 */
contract WebacyToken is ERC20 {
    constructor(
        uint256 initialSupply,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title WebacyToken
 * Reference ERC1155 token for testing purposes
 * with easy method for creating many tokenIds
 *
 */
contract Webacy1155 is ERC1155 {
    uint256 public tokenID = 0;
    mapping(uint256 => uint256) public existence;
    string public symbol;

    constructor(string memory _symbol)
        ERC1155("https://webacy.example/api/item/{id}.json")
    {
        symbol = _symbol;
    }

    function selfMint(uint256 _amount) external {
        privateMint(_amount, msg.sender);
    }

    function publicMint(uint256 _amount, address _address) external {
        privateMint(_amount, _address);
    }

    function privateMint(uint256 _amount, address _address) private {
        _mint(_address, tokenID, _amount, "");
        existence[tokenID] = _amount;
        tokenID++;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title WebacyToken
 * Reference ERC721 token for testing purposes
 */
contract WebacyNFT is ERC721 {
    mapping(string => uint8) public hashes;
    uint256 _tokenIds = 0;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function mint(address recipient, string memory hash)
        public
        returns (uint256)
    {
        require(hashes[hash] != 1, "Hash already minted");

        hashes[hash] = 1;

        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);

        _tokenIds++;

        return newItemId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
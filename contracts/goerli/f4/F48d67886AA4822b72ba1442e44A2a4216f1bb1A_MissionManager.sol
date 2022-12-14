// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "Initializable.sol";
import "IMissionManager.sol";
import "IRentalPool.sol";
import "IWalletFactory.sol";
import "IGamingWallet.sol";
import "NFTRental.sol";
import "AccessManager.sol";

contract MissionManager is Initializable, AccessManager, IMissionManager {
    IRentalPool public rentalPool;
    IWalletFactory public walletFactory;

    mapping(string => NFTRental.Mission) public readyMissions;
    mapping(string => NFTRental.Mission) public ongoingMissions;
    mapping(string => NFTRental.MissionDates) public missionDates;
    mapping(address => string[]) public tenantOngoingMissionUuid;
    mapping(address => string[]) public tenantReadyMissionUuid;

    modifier onlyRentalPool() {
        require(
            msg.sender == address(rentalPool),
            "Only Rental Pool is authorized"
        );
        _;
    }

    function initialize(IRoleRegistry _roleRegistry, address _rentalPoolAddress)
        external
        initializer
    {
        AccessManager.setRoleRegistry(_roleRegistry);
        rentalPool = IRentalPool(_rentalPoolAddress);
    }

    function setWalletFactory(address _walletFactoryAdr)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        walletFactory = IWalletFactory(_walletFactoryAdr);
    }

    function oasisClaimForMission(
        address _gamingWallet,
        address _gameContract,
        bytes calldata data_
    ) external override onlyRole(Roles.REWARD_CLAIMER) returns (bytes memory) {
        IGamingWallet gamingWallet = IGamingWallet(_gamingWallet);
        bytes memory returnData = gamingWallet.oasisClaimForward(
            _gameContract,
            data_
        );
        return returnData;
    }

    function postMissions(NFTRental.Mission[] calldata mission)
        external
        override
    {
        for (uint256 i = 0; i < mission.length; i++) {
            require(
                msg.sender == mission[i].owner,
                "Sender is not mission owner"
            );
            require(
                !tenantHasOngoingMissionForDapp(
                    mission[i].tenant,
                    mission[i].dappId
                ),
                "Tenant already have ongoing mission for dapp"
            );
            require(
                !isMissionPosted(mission[i].uuid),
                "Uuid has already been used"
            );
            rentalPool.verifyAndStake(mission[i]);
            readyMissions[mission[i].uuid] = mission[i];
            tenantReadyMissionUuid[mission[i].tenant].push(mission[i].uuid);
            missionDates[mission[i].uuid] = NFTRental.MissionDates({
                postDate: block.timestamp,
                startDate: 0,
                cancelDate: 0,
                stopDate: 0
            });
            emit MissionPosted(mission[i]);
        }
    }

    function cancelMissions(string[] calldata _uuid) external override {
        for (uint256 i = 0; i < _uuid.length; i++) {
            NFTRental.Mission memory curMission = readyMissions[_uuid[i]];
            require(msg.sender == curMission.owner, "Not mission owner");
            rentalPool.sendNFTsBack(curMission);
            _rmReadyMissionUuid(curMission.tenant, _uuid[i]);
            missionDates[_uuid[i]].cancelDate = block.timestamp;
            emit MissionCanceled(curMission);
        }
    }

    function startMission(string calldata _uuid) external override {
        NFTRental.Mission memory missionToStart = readyMissions[_uuid];
        require(msg.sender == missionToStart.tenant, "Not mission tenant");
        require(
            !tenantHasOngoingMissionForDapp(msg.sender, missionToStart.dappId),
            "Tenant already have ongoing mission for dapp"
        );
        _createWalletIfRequired();
        address _gamingWalletAddress = walletFactory.getGamingWallet(
            msg.sender
        );
        rentalPool.sendStartingMissionNFT(
            missionToStart.uuid,
            _gamingWalletAddress
        );
        tenantOngoingMissionUuid[msg.sender].push(_uuid);
        ongoingMissions[missionToStart.uuid] = missionToStart;
        _rmReadyMissionUuid(msg.sender, _uuid);
        delete readyMissions[missionToStart.uuid];
        missionDates[missionToStart.uuid].startDate = block.timestamp;
        emit MissionStarted(missionToStart);
    }

    function stopMission(string calldata _uuid) external override {
        NFTRental.Mission memory curMission = ongoingMissions[_uuid];
        require(msg.sender == curMission.owner, "Not mission owner");
        missionDates[curMission.uuid].stopDate = block.timestamp;
        emit MissionTerminating(curMission);
    }

    function terminateMission(string calldata _uuid)
        external
        override
        onlyRole(Roles.MISSION_TERMINATOR)
    {
        require(missionDates[_uuid].stopDate > 0, "Mission is not terminating");
        _terminateMission(_uuid);
    }

    function terminateMissionFallback(string calldata _uuid) external override {
        require(
            block.timestamp >= missionDates[_uuid].stopDate + 15 days,
            "15 days should pass"
        );
        NFTRental.Mission memory curMission = ongoingMissions[_uuid];
        require(msg.sender == curMission.owner, "Not mission owner");
        _terminateMission(_uuid);
    }

    function getOngoingMission(string calldata _uuid)
        external
        view
        override
        returns (NFTRental.Mission memory mission)
    {
        return ongoingMissions[_uuid];
    }

    function getReadyMission(string calldata _uuid)
        external
        view
        override
        returns (NFTRental.Mission memory mission)
    {
        return readyMissions[_uuid];
    }

    function getTenantOngoingMissionUuid(address _tenant)
        public
        view
        override
        returns (string[] memory ongoingMissionsUuids)
    {
        return tenantOngoingMissionUuid[_tenant];
    }

    function getTenantReadyMissionUuid(address _tenant)
        public
        view
        override
        returns (string[] memory readyMissionsUuids)
    {
        return tenantReadyMissionUuid[_tenant];
    }

    function tenantHasOngoingMissionForDapp(
        address _tenant,
        string memory _dappId
    ) public view override returns (bool hasMissionForDapp) {
        string[] memory tenantMissionsUuid = tenantOngoingMissionUuid[_tenant];
        for (uint32 i; i < tenantMissionsUuid.length; i++) {
            NFTRental.Mission memory curMission = ongoingMissions[
                tenantMissionsUuid[i]
            ];
            if (
                keccak256(bytes(curMission.dappId)) == keccak256(bytes(_dappId))
            ) {
                return true;
            }
        }
        return false;
    }

    function tenantHasReadyMissionForDapp(
        address _tenant,
        string memory _dappId
    ) public view override returns (bool hasMissionForDapp) {
        string[] memory tenantMissionsUuid = tenantReadyMissionUuid[_tenant];
        for (uint32 i; i < tenantMissionsUuid.length; i++) {
            NFTRental.Mission memory curMission = readyMissions[
                tenantMissionsUuid[i]
            ];
            if (
                keccak256(bytes(curMission.dappId)) == keccak256(bytes(_dappId))
            ) {
                return true;
            }
        }
        return false;
    }

    function getTenantReadyMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) public view override returns (uint256 uuidPosition) {
        string[] memory list = tenantReadyMissionUuid[_tenant];
        for (uint32 i; i < list.length; i++) {
            if (keccak256(bytes(list[i])) == keccak256(bytes(_uuid))) {
                return i;
            }
        }
        return list.length + 1;
    }

    function getTenantOngoingMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) public view override returns (uint256 uuidPosition) {
        string[] memory list = tenantOngoingMissionUuid[_tenant];
        for (uint32 i; i < list.length; i++) {
            if (keccak256(bytes(list[i])) == keccak256(bytes(_uuid))) {
                return i;
            }
        }
        return list.length + 1;
    }

    function isMissionPosted(string calldata _uuid)
        public
        view
        override
        returns (bool)
    {
        return missionDates[_uuid].postDate > 0;
    }

    function batchMissionsDates(string[] calldata _uuid)
        public
        view
        override
        returns (NFTRental.MissionDates[] memory)
    {
        NFTRental.MissionDates[]
            memory missionsDates = new NFTRental.MissionDates[](_uuid.length);
        for (uint256 i = 0; i < _uuid.length; i++) {
            missionsDates[i] = missionDates[_uuid[i]];
        }
        return missionsDates;
    }

    function _createWalletIfRequired() internal {
        if (!walletFactory.hasGamingWallet(msg.sender)) {
            walletFactory.createWallet(msg.sender);
        }
    }

    function _rmMissionUuid(address _tenant, string calldata _uuid) internal {
        uint256 index = getTenantOngoingMissionUuidIndex(_tenant, _uuid);
        uint256 ongoingMissionLength = tenantOngoingMissionUuid[_tenant].length;
        tenantOngoingMissionUuid[_tenant][index] = tenantOngoingMissionUuid[
            _tenant
        ][ongoingMissionLength - 1];
        tenantOngoingMissionUuid[_tenant].pop();
        delete ongoingMissions[_uuid];
    }

    function _rmReadyMissionUuid(address _tenant, string calldata _uuid)
        internal
    {
        uint256 index = getTenantReadyMissionUuidIndex(_tenant, _uuid);
        uint256 readyMissionLength = tenantReadyMissionUuid[_tenant].length;
        tenantReadyMissionUuid[_tenant][index] = tenantReadyMissionUuid[
            _tenant
        ][readyMissionLength - 1];
        tenantReadyMissionUuid[_tenant].pop();
        delete readyMissions[_uuid];
    }

    function _terminateMission(string calldata _uuid) internal {
        NFTRental.Mission memory curMission = ongoingMissions[_uuid];
        address tenant = curMission.tenant;
        address gamingWalletAddress = walletFactory.getGamingWallet(tenant);
        IGamingWallet(gamingWalletAddress).bulkReturnAsset(
            curMission.owner,
            curMission.collections,
            curMission.tokenIds
        );
        _rmMissionUuid(tenant, _uuid);
        emit MissionTerminated(curMission);
    }

    function _requireStakedNFT(
        address[] calldata _collections,
        uint256[][] calldata _tokenIds
    ) internal view {
        for (uint32 j = 0; j < _tokenIds.length; j++) {
            for (uint32 k = 0; k < _tokenIds[j].length; k++) {
                require(
                    rentalPool.isNFTStaked(
                        _collections[j],
                        msg.sender,
                        _tokenIds[j][k]
                    ) == true,
                    "NFT is not staked"
                );
            }
        }
    }

    function _verifyParam(
        address[] calldata _collections,
        uint256[][] calldata _tokenIds
    ) internal pure {
        require(
            _collections.length == _tokenIds.length,
            "Incorrect lengths in tokenIds and collections"
        );
        require(_tokenIds[0][0] != 0, "At least one NFT required");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IERC721.sol";
import "NFTRental.sol";

// Management contract for NFT rentals.
// This mostly stores rental agreements and does the transfer with the wallet contracts
interface IMissionManager {
    event MissionPosted(NFTRental.Mission mission);

    event MissionCanceled(NFTRental.Mission mission);

    event MissionStarted(NFTRental.Mission mission);

    event MissionTerminating(NFTRental.Mission mission);

    event MissionTerminated(NFTRental.Mission mission);

    function setWalletFactory(address _walletFactoryAdr) external;

    function oasisClaimForMission(
        address gamingWallet,
        address gameContract,
        bytes calldata data_
    ) external returns (bytes memory);

    function postMissions(NFTRental.Mission[] calldata mission) external;

    function cancelMissions(string[] calldata _uuid) external;

    function startMission(string calldata _uuid) external;

    function stopMission(string calldata _uuid) external;

    function terminateMission(string calldata _uuid) external;

    function terminateMissionFallback(string calldata _uuid) external;

    function getOngoingMission(string calldata _uuid)
        external
        view
        returns (NFTRental.Mission calldata mission);

    function getReadyMission(string calldata _uuid)
        external
        view
        returns (NFTRental.Mission memory mission);

    function getTenantOngoingMissionUuid(address _tenant)
        external
        view
        returns (string[] memory missionUuid);

    function getTenantReadyMissionUuid(address _tenant)
        external
        view
        returns (string[] memory missionUuid);

    function tenantHasOngoingMissionForDapp(
        address _tenant,
        string memory _dappId
    ) external view returns (bool hasMissionForDapp);

    function tenantHasReadyMissionForDapp(
        address _tenant,
        string memory _dappId
    ) external view returns (bool hasMissionForDapp);

    function getTenantReadyMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) external view returns (uint256 uuidPosition);

    function getTenantOngoingMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) external view returns (uint256 uuidPosition);

    function isMissionPosted(string calldata _uuid)
        external
        view
        returns (bool);

    function batchMissionsDates(string[] calldata _uuid)
        external
        view
        returns (NFTRental.MissionDates[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

library NFTRental {
    struct Mission {
        string uuid;
        string dappId;
        address owner;
        address tenant;
        address[] collections;
        uint256[][] tokenIds;
        uint256 tenantShare;
    }

    struct MissionDates {
        uint256 postDate;
        uint256 startDate;
        uint256 cancelDate;
        uint256 stopDate;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IERC721.sol";
import "NFTRental.sol";

// Pool to hold the staked NFTs of one collection that are not currently rented out
interface IRentalPool {
    event NFTStaked(address collection, address owner, uint256 tokenId);

    event NFTUnstaked(address collection, address owner, uint256 tokenId);

    function setMissionManager(address _rentalManager) external;

    function setWalletFactory(address _walletFactory) external;

    function whitelistOwners(address[] calldata _owners) external;

    function removeWhitelistedOwners(address[] calldata _owners) external;

    function verifyAndStake(NFTRental.Mission calldata newMission) external;

    function sendStartingMissionNFT(
        string calldata _uuid,
        address _gamingWallet
    ) external;

    function sendNFTsBack(NFTRental.Mission calldata mission) external;

    function isNFTStaked(
        address collection,
        address owner,
        uint256 tokenId
    ) external view returns (bool isStaked);

    function isOwnerWhitelisted(address _owner)
        external
        view
        returns (bool isWhitelisted);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

// Factory to create gaming wallets
interface IWalletFactory {
    event WalletCreated(address owner, address walletAddress);

    function createWallet() external;

    function createWallet(address _owner) external;

    function resetTenantGamingWallet(address _tenant) external;

    function changeRentalPoolAddress(address _rentalPool) external;

    function changeProxyRegistryAddress(address _proxyRegistry) external;

    function changeRevenueManagerAddress(address _revenueManager) external;

    function addCollectionForDapp(string calldata _dappId, address _collection)
        external;

    function removeCollectionForDapp(
        string calldata _dappId,
        address _collection
    ) external;

    function verifyCollectionForUniqueDapp(
        string calldata _dappId,
        address[] calldata _collections
    ) external view returns (bool uniqueDapp);

    function getGamingWallet(address owner)
        external
        view
        returns (address gamingWalletAddress);

    function hasGamingWallet(address owner)
        external
        view
        returns (bool hasWallet);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

// Generic wallet contract to interact with GamingProxies
// TODO: Implement EIP 1271 to get isValidSignature function for games
interface IGamingWallet {
    event NFTDeposited(address collection, uint256 tokenID);
    event NFTWithdrawn(address collection, uint256 tokenID);
    event NFTReturned(address collection, uint256 tokenID);

    function bulkReturnAsset(
        address returnAddress,
        address[] calldata _collection,
        uint256[][] calldata _tokenID
    ) external;

    // Functions to allow users to deposit own assets
    function depositAsset(address collection, uint256 id) external;

    function withdrawAsset(address collection, uint256 id) external;

    // Generic functions to run delegatecalls with the game proxies
    function forwardCall(address gameContract, bytes calldata data_)
        external
        returns (bytes memory);

    function oasisClaimForward(address gameContract, bytes calldata data_)
        external
        returns (bytes memory);

    function oasisDistributeERC20Rewards(
        address _rewardToken,
        address _rewardReceiver,
        uint256 _rewardAmount
    ) external;

    function oasisDistributeERC721Rewards(
        address _receiver,
        address _collection,
        uint256 _tokenId
    ) external;

    function oasisDistributeERC1155Rewards(
        address _receiver,
        address _collection,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        returns (bytes4 magicValue);

    // Will be overridden to return the owner of the wallet
    function owner() external view returns (address);

    function revenueManager() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "RoleLibrary.sol";

import "IRoleRegistry.sol";

/**
 * @notice Provides modifiers for authorization
 */
contract AccessManager {
    IRoleRegistry internal roleRegistry;
    bool public isInitialised = false;

    modifier onlyRole(bytes32 role) {
        require(roleRegistry.hasRole(role, msg.sender), "Unauthorized access");
        _;
    }

    modifier onlyGovernance() {
        require(
            roleRegistry.hasRole(Roles.ADMIN, msg.sender),
            "Unauthorized access"
        );
        _;
    }

    modifier onlyRoles2(bytes32 role1, bytes32 role2) {
        require(
            roleRegistry.hasRole(role1, msg.sender) ||
                roleRegistry.hasRole(role2, msg.sender),
            "Unauthorized access"
        );
        _;
    }

    function setRoleRegistry(IRoleRegistry _roleRegistry) public {
        require(!isInitialised, "RoleRegistry already initialised");
        roleRegistry = _roleRegistry;
        isInitialised = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

library Roles {
    bytes32 internal constant ADMIN = "admin";
    bytes32 internal constant REWARD_CLAIMER = "reward_claimer";
    bytes32 internal constant MISSION_TERMINATOR = "mission_terminator";
    bytes32 internal constant FUNCTION_WHITELISTER = "function_whitelister";
    bytes32 internal constant PROXY_SETTER = "proxy_setter";
    bytes32 internal constant OWNER_WHITELISTER = "owner_whitelister";
    bytes32 internal constant REWARD_DISTRIBUTOR = "reward_distributor";
    bytes32 internal constant GAMECOLLECTION_SETTER = "gamecollection_setter";
    bytes32 internal constant PROXY_REGISTRY = "proxy_registry";
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IRoleRegistry {
    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 _role, address account) external;

    function hasRole(bytes32 _role, address account)
        external
        view
        returns (bool);
}
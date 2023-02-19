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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IoDAO.sol";
import "./interfaces/iInstanceDAO.sol";
import "./interfaces/IMembrane.sol";
import "./interfaces/IMember1155.sol";

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./errors.sol";

contract MembraneRegistry {
    address MRaddress;
    IoDAO ODAO;
    IMemberRegistry iMR;

    mapping(uint256 => Membrane) getMembraneById;
    mapping(address => uint256) usesMembrane;

    constructor(address ODAO_) {
        iMR = IMemberRegistry(msg.sender);
        ODAO = IoDAO(ODAO_);
    }

    error Membrane__membraneNotFound();
    error Membrane__aDAOnot();
    error Membrane__ExpectedODorD();
    error Membrane__MembraneChangeLimited();
    error Membrane__EmptyFieldOnMembraneCreation();
    error Membrane__onlyODAOToSetEndpoint();
    error Membrane__SomethingWentWrong();

    event CreatedMembrane(uint256 id, string metadata);
    event ChangedMembrane(address they, uint256 membrane);
    event gCheckKick(address indexed who);

    /// @notice creates membrane. Used to control and define.
    /// @notice To be read and understood as: Givent this membrane, of each of the tokens_[x], the user needs at least balances_[x].
    /// @param tokens_ ERC20 or ERC721 token addresses array. Each is used as a constituent item of the membrane and condition for
    /// @param tokens_ belonging or not. Membership is established by a chain of binary claims whereby
    /// @param tokens_ the balance of address checked needs to satisfy all balances_ of all tokens_ stated as benchmark for belonging
    /// @param balances_ amounts required of each of tokens_. The order of required balances needs to map to token addresses.
    /// @param meta_ anything you want. Preferably stable CID for reaching aditional metadata such as an IPFS hash of type string.
    function createMembrane(address[] memory tokens_, uint256[] memory balances_, string memory meta_)
        public
        returns (uint256 id)
    {
        /// @dev consider negative as feature . [] <- isZero. sybil f
        /// @dev @security erc165 check
        if (!((tokens_.length / balances_.length) * bytes(meta_).length >= 1)) {
            revert Membrane__EmptyFieldOnMembraneCreation();
        }
        Membrane memory M;
        M.tokens = tokens_;
        M.balances = balances_;
        M.meta = meta_;
        id = uint256(keccak256(abi.encode(M))) % 1 ether;
        getMembraneById[id] = M;

        emit CreatedMembrane(id, meta_);
    }

    function setMembrane(uint256 membraneID_, address dao_) external returns (bool) {
        if ((msg.sender != dao_) && (msg.sender != address(ODAO))) revert Membrane__MembraneChangeLimited();
        if (getMembraneById[membraneID_].tokens.length == 0) revert Membrane__membraneNotFound();

        usesMembrane[dao_] = membraneID_;
        emit ChangedMembrane(dao_, membraneID_);
        return true;
    }

    function setMembraneEndpoint(uint256 membraneID_, address dao_, address owner_) external returns (bool) {
        if (msg.sender != address(ODAO)) revert Membrane__onlyODAOToSetEndpoint();
        if (address(uint160(membraneID_)) == owner_) {
            if (bytes(getMembraneById[membraneID_].meta).length == 0) {
                Membrane memory M;
                M.meta = "endpoint";
                getMembraneById[membraneID_] = M;
            }
            usesMembrane[dao_] = membraneID_;
            return true;
        } else {
            revert Membrane__SomethingWentWrong();
        }
    }

    /// @notice checks if a given address is member in a given DAO.
    /// @notice answers: Does who_ belong to DAO_?
    /// @param who_ what address to check
    /// @param DAO_ in what DAO or subDAO do you want to check if who_ b
    function checkG(address who_, address DAO_) public view returns (bool s) {
        Membrane memory M = getInUseMembraneOfDAO(DAO_);
        uint256 i;
        s = true;
        for (i; i < M.tokens.length;) {
            s = s && (IERC20(M.tokens[i]).balanceOf(who_) >= M.balances[i]);
            unchecked {
                ++i;
            }
        }
    }

    //// @notice checks if a given address (who_) is a member in the given (dao_). Same as checkG()
    ///  @notice if any of the balances checks specified in the membrane fails, the membership token of checked address is burned
    /// @notice this is a defensive, think auto-imune mechanism.
    /// @param who_ checked address
    /// @dev @todo retrace once again gCheck. Consider spam vectors.
    function gCheck(address who_, address DAO_) external returns (bool s) {
        if (iMR.balanceOf(who_, uint160(bytes20(DAO_))) == 0) return false;
        s = checkG(who_, DAO_);
        if (s) return true;
        if (!s) iMR.gCheckBurn(who_, DAO_);

        //// removed liquidate on kick . this burns membership token but lets user own internaltoken. @security consider

        emit gCheckKick(who_);
    }

    /// @notice returns the meta field of a membrane given its id
    /// @param id_ membrane id_
    function entityData(uint256 id_) external view returns (string memory) {
        return getMembraneById[id_].meta;
    }

    /// @notice returns the membrane given its id_
    /// @param id_ id of membrane you want fetched
    /// @return Membrane struct
    function getMembrane(uint256 id_) external view returns (Membrane memory) {
        return getMembraneById[id_];
    }

    /// @notice checks if a given id_ belongs to an instantiated membrane
    function isMembrane(uint256 id_) external view returns (bool) {
        return (getMembraneById[id_].tokens.length > 0);
    }

    /// @notice fetches the id of the active membrane for given provided DAO adress. Returns 0x0 if none.
    /// @param DAOaddress_ address of DAO (or subDAO) to retrieve mebrane id of
    function inUseMembraneId(address DAOaddress_) public view returns (uint256 ID) {
        return usesMembrane[DAOaddress_];
    }

    /// @notice fetches the in use membrane of DAO
    /// @param DAOAddress_ address of DAO (or subDAO) to retrieve in use Membrane of given DAO or subDAO address
    /// @return Membrane struct
    function getInUseMembraneOfDAO(address DAOAddress_) public view returns (Membrane memory) {
        return getMembraneById[usesMembrane[DAOAddress_]];
    }

    /// @notice returns the uri or CID metadata of given DAO address
    /// @param DAOaddress_ address of DAO to fetch `.meta` of used membrane
    /// @return string
    function inUseUriOf(address DAOaddress_) external view returns (string memory) {
        return getInUseMembraneOfDAO(DAOaddress_).meta;
    }
}

/*//////////////////////////////////////////////////////////////
                                 errors
        //////////////////////////////////////////////////////////////*/

error DAOinstance__NotOwner();
error DAOinstance__TransferFailed();
error DAOinstance__Unqualified();
error DAOinstance__NotMember();
error DAOinstance__InvalidMembrane();
error DAOinstance__CannotUpdate();
error DAOinstance__LenMismatch();
error DAOinstance__Over100();
error DAOinstance__nonR();
error DAOinstance__NotEndpoint1();
error DAOinstance__NotEndpoint2();
error DAOinstance__OnlyODAO();
error DAOinstance__YouCantDoThat();
error DAOinstance__notmajority();
error DAOinstance__CannotLiquidate();
error DAOinstance__NotCallMaker();
error DAOinstance__alreadySet();
error DAOinstance__OnlyDAO();
error DAOinstance__HasNoSay();
error DAOinstance__itTransferFailed();
error DAOinstance__NotIToken();
error DAOinstance__isEndpoint();
error DAOinstance__NotYourEnpoint();
error DAOinstance__onlyMR();
error DAOinstance__invalidMembrane();
error DAOinstance_ExeCallFailed(bytes returnedDataByFailedCall);

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./structs.sol";

interface IMemberRegistry {
    function makeMember(address who_, uint256 id_) external returns (bool);

    function gCheckBurn(address who_, address DAO_) external returns (bool);

    /// onlyMembrane
    function howManyTotal(uint256 id_) external view returns (uint256);
    function setUri(string memory uri_) external;
    function uri(uint256 id) external view returns (string memory);

    function ODAOaddress() external view returns (address);
    function MembraneRegistryAddress() external view returns (address);
    function ExternalCallAddress() external view returns (address);

    function getRoots(uint256 startAt_) external view returns (address[] memory);
    function getEndpointsOf(address who_) external view returns (address[] memory);

    function getActiveMembershipsOf(address who_) external view returns (address[] memory entities);
    function getUriOf(address who_) external view returns (string memory);
    //// only ODAO

    function pushIsEndpoint(address) external;
    function pushAsRoot(address) external;
    //////////////////////// ERC1155

    ///// only odao
    function pushIsEndpointOf(address dao_, address endpointOwner_) external;

    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
     *     @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     *     MUST revert if `_to` is the zero address.
     *     MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
     *     MUST revert on any other error.
     *     MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     *     After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     *     @param _from    Source address
     *     @param _to      Target address
     *     @param _id      ID of the token type
     *     @param _value   Transfer amount
     *     @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
     *     @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     *     MUST revert if `_to` is the zero address.
     *     MUST revert if length of `_ids` is not the same as length of `_values`.
     *     MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
     *     MUST revert on any other error.
     *     MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     *     Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     *     After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     *     @param _from    Source address
     *     @param _to      Target address
     *     @param _ids     IDs of each token type (order and length must match _values array)
     *     @param _values  Transfer amounts per token type (order and length must match _ids array)
     *     @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
     * @notice Get the balance of an account's tokens.
     *     @param _owner  The address of the token holder
     *     @param _id     ID of the token
     *     @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
     * @notice Get the balance of multiple account/token pairs
     *     @param _owners The addresses of the token holders
     *     @param _ids    ID of the tokens
     *     @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
     *     @dev MUST emit the ApprovalForAll event on success.
     *     @param _operator  Address to add to the set of authorized operators
     *     @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Queries the approval status of an operator for a given owner.
     *     @param _owner     The owner of the tokens
     *     @param _operator  Address of authorized operator
     *     @return           True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMembrane {
    struct Membrane {
        address[] tokens;
        uint256[] balances;
        bytes meta;
    }

    function getMembrane(uint256 id) external view returns (Membrane memory);

    function setMembrane(uint256 membraneID_, address DAO_) external returns (bool);

    function setMembraneEndpoint(uint256 membraneID_, address subDAOaddr, address owner) external returns (bool);

    function inUseMembraneId(address DAOaddress_) external view returns (uint256 Id);

    function inUseUriOf(address DAOaddress_) external view returns (string memory);

    function getInUseMembraneOfDAO(address DAOAddress_) external view returns (Membrane memory);

    function createMembrane(address[] memory tokens_, uint256[] memory balances_, string memory meta_)
        external
        returns (uint256);
    function isMembrane(uint256 id_) external view returns (bool);

    function checkG(address who, address DAO_) external view returns (bool s);

    function gCheck(address who_, address DAO_) external returns (bool);

    function entityData(uint256 id_) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IMember1155.sol";

interface IoDAO {
    function isDAO(address toCheck) external view returns (bool);

    function createDAO(address BaseTokenAddress_) external returns (address newDAO);

    function createSubDAO(uint256 membraneID_, address parentDAO_) external returns (address subDAOaddr);

    function getParentDAO(address child_) external view returns (address);

    function getDAOsOfToken(address parentToken) external view returns (address[] memory);

    function getDAOfromID(uint256 id_) external view returns (address);

    function getTrickleDownPath(address floor_) external view returns (address[] memory);

    function CSRvault() external view returns (address);

    function MR() external view returns (address MEMBERRegistryAddress);

    function MB() external view returns (address memBRANEregistryAddress);


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface iInstanceDAO {
    function signalInflation(uint256 percentagePerYear_) external returns (uint256 inflationRate);

    function mintMembershipToken(address to_) external returns (bool);

    function changeMembrane(uint256 membraneId_) external returns (uint256 membraneID);

    function executeCall(uint256 externalCallId) external returns (uint256);

    function distributiveSignal(uint256[] memory cronoOrderedDistributionAmts) external returns (uint256);

    function multicall(bytes[] memory) external returns (bytes[] memory results);

    function executeExternalLogic(uint256 callId_) external returns (bool);

    function feedMe() external returns (uint256);

    function redistributeSubDAO(address subDAO_) external returns (uint256);

    function mintInflation() external returns (uint256);

    function feedStart() external returns (uint256 minted);

    function withdrawBurn(uint256 amt_) external returns (uint256 amtWithdrawn);

    function gCheckPurge(address who_) external;

    /// only MR

    // function cleanIndecisionLog() external;

    /// view

    function getActiveIndecisions() external view returns (uint256[] memory);

    function stateOfExpressed(address user_, uint256 prefID_) external view returns (uint256[3] memory pref);

    function internalTokenAddress() external view returns (address);

    function endpoint() external view returns (address);

    function baseTokenAddress() external view returns (address);

    function baseID() external view returns (uint256);

    function instantiatedAt() external view returns (uint256);

    function getUserReDistribution(address ofWhom) external view returns (uint256[] memory);

    function baseInflationRate() external view returns (uint256);

    function baseInflationPerSec() external view returns (uint256);

    function isMember(address who_) external view returns (bool);

    function parentDAO() external view returns (address);

    function getILongDistanceAddress() external view returns (address);

    function uri() external view returns (string memory);
}

struct Membrane {
    address[] tokens;
    uint256[] balances;
    string meta;
}
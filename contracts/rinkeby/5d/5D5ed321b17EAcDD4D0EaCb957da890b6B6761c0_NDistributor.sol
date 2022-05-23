//TODO:
//
// - User structure — should describe the "vault" of the user — keep track of his assets and utils [+]
//
// - Write getter functions to read info about user vaults (users mapping) [+]
// - Get user DNTs [+]
// - Get user utils [+]
// - Get user DNT in util [+]
// - Get user liquid DNT [+]
// - Get user utils in dnt [+]
//
// - Add DNT balance getter function for user from DNT contract [+]
// - DNT removal (burn) logic [+]
// - Token transfer logic (should keep track of user utils) [+]
// - Implement NULL util logic
// - Implement all checks (correct util, dnt, is util active)
// - Figure out token transfer things permissions
//
// - Make universal DNT interface
//     - setInterface
//     - mint
//     - burn
//     - balance
//     - transfer
//
// - Add the rest of the DNT token functions (pause, snapshot, etc) to interface
// - Add those functions to distributor
// - Make sure ownership over DNT tokens isn't lost
// - Add proxy contract for managing access to DNT contracts


// SET-UP:
// 1. Deploy nDistributor
// 2. Deploy nASTR, pass distributor address as constructor arg (makes nDistributor the owner)
// 3. Call "setAstrInterface" in nDistributor with nASTR contract address

// rinkeby addr: 0x5D5ed321b17EAcDD4D0EaCb957da890b6B6761c0
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../libs/@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IDNT.sol";


/*
 * @notice ERC20 DNT token distributor contract
 *
 * Features:
 * - Ownable
 */
contract NDistributor is Ownable {

    // DECLARATIONS
    //
    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- USER MANAGMENT
    // -------------------------------------------------------------------------------------------------------

    // @notice                         describes DntAsset structure
    // @dev                            dntInUtil => describes how many DNTs are attached to specific utility
    // @dev                            dntLiquid => describes how many DNTs are liquid and available for imidiate use
    struct                             DntAsset {
        mapping (string => uint256)    dntInUtil;
        string[]                       userUtils;
        uint256                        dntLiquid;
    }

    // @notice                         describes user structure
    // @dev                            dnt => tracks specific DNT token
    struct                             User {
        mapping (string => DntAsset)   dnt;
        string[]                       userDnts;
        string[]                       userUtilities;
    }

    // @dev                            users => describes the user and his portfolio
    mapping (address => User)          users;





    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- UTILITY MANAGMENT
    // -------------------------------------------------------------------------------------------------------

    // @notice                         defidescribesnes utility (Algem offer\opportunity) struct
    struct                             Utility {
        string                         utilityName;
        bool                           isActive;
    }

    // @notice                         keeps track of all utilities
    Utility[] public                   utilityDB;

    // @notice                         allows to list and display all utilities
    string[]                           utilities;

    // @notice                         keeps track of utility ids
    mapping (string => uint) public    utilityId;





    // -------------------------------------------------------------------------------------------------------
    // -------------------------------- DNT TOKENS MANAGMENT
    // -------------------------------------------------------------------------------------------------------

    // @notice                         defidescribesnes DNT token struct
    struct                             Dnt {
        string                         dntName;
        bool                           isActive;
    }

    // @notice                         keeps track of all DNTs
    Dnt[] public                       dntDB;

    // @notice                         allows to list and display all DNTs
    string[]                           dnts;

    // @notice                         keeps track of DNT ids
    mapping (string => uint) public    dntId;

    // @notice                          DNT token contract interface
    address public                      DNTContractAdress;
    IDNT                                DNTContract;





    // FUNCTIONS
    //
    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Asset managment (utilities and DNTs tracking)
    // -------------------------------------------------------------------------------------------------------

    // @notice                         initializes utilityDB & dntDB
    // @dev                            first element in mapping & non-existing entry both return 0
    //                                 so we initialize it to avoid confusion
    // @dev                            "null" utility also means tokens not connected to utility
    //                                 these could be used in any utility
    //                                 for example, after token trasfer, reciever will get "null" utility
    constructor() {
        utilityDB.push(Utility("null", true));
        dntDB.push(Dnt("null", false));
        DNTContractAdress = address(0x00);
    }

    // @notice                         returns the list of all utilities
    function                           listUtilities() external view returns(string[] memory) {
        return utilities;
    }

    // @notice                         returns the list of all DNTs
    function                           listDnts() external view returns(string[] memory) {
        return dnts;
    }

    // @notice                         adds new utility to the DB, activates it by default
    // @param                          [string] _newUtility => name of the new utility
    function                           addUtility(string memory _newUtility) external onlyOwner {
        uint                           lastId = utilityDB.length;

        utilityId[_newUtility] = lastId;
        utilityDB.push(Utility(_newUtility, true));
        utilities.push(_newUtility);
    }

    // @notice                         adds new DNT to the DB, activates it by default
    // @param                          [string] _newDnt => name of the new DNT
    function                           addDnt(string memory _newDnt) external onlyOwner { // <--------- also set contract address for interface here
        uint                           lastId = dntDB.length;

        dntId[_newDnt] = lastId;
        dntDB.push(Dnt(_newDnt, true));
        dnts.push(_newDnt);
    }

    // @notice                         allows to activate\deactivate utility
    // @param                          [uint256] _id => utility id
    // @param                          [bool] _state => desired state
    function                           setUtilityStatus(uint256 _id, bool _state) public onlyOwner {
        utilityDB[_id].isActive = _state;
    }

    // @notice                         allows to activate\deactivate DNT
    // @param                          [uint256] _id => DNT id
    // @param                          [bool] _state => desired state
    function                           setDntStatus(uint256 _id, bool _state) public onlyOwner { // -----
        dntDB[_id].isActive = _state;
    }

    // @notice                         returns a list of user's DNT tokens in possession
    // @param                          [address] _user => user address
    function                           listUserDnts(address _user) public view returns(string[] memory) {
        return (users[_user].userDnts);
    }

    // @notice                         returns ammount of liquid DNT toknes in user's possesion
    // @param                          [address] _user => user address
    // @param                          [string] _dnt => DNT token name
    function                           getUserLiquidDnt(address _user, string memory _dnt) public view returns(uint256) {
        return (users[_user].dnt[_dnt].dntLiquid);
    }

    // @notice                         returns ammount of DNT toknes of user in utility
    // @param                          [address] _user => user address
    // @param                          [string] _util => utility name
    // @param                          [string] _dnt => DNT token name
    function                           getUserDntBalanceInUtil(address _user, string memory _util, string memory _dnt) public view returns(uint256) {
        return (users[_user].dnt[_dnt].dntInUtil[_util]);
    }

    // @notice                         returns which utilities are used with specific DNT token
    // @param                          [address] _user => user address
    // @param                          [string] _dnt => DNT token name
    function                           getUserUtilsInDnt(address _user, string memory _dnt) public view returns(string[] memory) {
        return (users[_user].dnt[_dnt].userUtils);
    }

    // @notice                         returns user's DNT balance
    // @param                          [address] _user => user address
    // @param                          [string] _dnt => DNT token name
    function                           getUserDntBalance(address _user, string memory _dnt) public returns(uint256) { // <--------- make universal dnt interface
        require(DNTContractAdress != address(0x00), "Interface not set!");

        return (DNTContract.balanceOf(_user));
    }





    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Distribution logic
    // -------------------------------------------------------------------------------------------------------

    // @notice                         issues new tokens
    // @param                          [address] _to => token recepient
    // @param                          [uint256] _amount => amount of tokens to mint
    // @param                          [string] _utility => minted dnt utility
    // @param                          [string] _dnt => minted dnt
    function                           issueDnt(address _to, uint256 _amount, string memory _utility, string memory _dnt) public { // <-------- DNT contract selection needed
        uint256                        id;

        require(DNTContractAdress != address(0x00), "Interface not set!");
        require((id = utilityId[_utility]) > 0, "Non-existing utility!");
        require(utilityDB[id].isActive == true, "Inactive utility!");

        _addDntToUser(_dnt, users[_to].userDnts);
        _addUtilityToUser(_utility, users[_to].userUtilities);
        _addUtilityToUser(_utility, users[_to].dnt[_dnt].userUtils);

        users[_to].dnt[_dnt].dntInUtil[_utility] += _amount;
        users[_to].dnt[_dnt].dntLiquid += _amount;
        DNTContract.mintNote(_to, _amount);
    }

    // @notice                         adds dnt string to user array of dnts for tracking which assets are in possession
    // @param                          [string] _dnt => name of the dnt token
    // @param                          [string[] ] localUserDnts => array of user's dnts
    function                           _addDntToUser(string memory _dnt, string[] storage localUserDnts) internal {
        uint256                        id = dntId[_dnt];
        uint                           l;
        uint                           i = 0;

        require(utilityDB[id].isActive == true, "Non-existing DNT!");
        require(dntDB[id].isActive == true, "Inactive DNT token!");

        l = localUserDnts.length;
        for (i; i < l; i++) {
            if (keccak256(abi.encodePacked(localUserDnts[i])) == keccak256(abi.encodePacked(_dnt))) {
                return;
            }
        }
        localUserDnts.push(_dnt);
        return;
    }

    // @notice                         adds utility string to user array of utilities for tracking which assets are in possession
    // @param                          [string] _utility => name of the utility token
    // @param                          [string[] ] localUserUtilities => array of user's utilities
    function                           _addUtilityToUser(string memory _utility, string[] storage localUserUtilities) internal {
        uint                           l;
        uint                           i = 0;

        l = localUserUtilities.length;
        for (i; i < l; i++) {
            if (keccak256(abi.encodePacked(localUserUtilities[i])) == keccak256(abi.encodePacked(_utility))) {
                return;
            }
        }
        localUserUtilities.push(_utility);
        return;
    }

    // @notice                         removes tokens from circulation
    // @param                          [address] _account => address to burn from
    // @param                          [uint256] _amount => amount of tokens to burn
    // @param                          [string] _utility => minted dnt utility
    // @param                          [string] _dnt => minted dnt
    function                           removeDnt(address _account, uint256 _amount, string memory _utility, string memory _dnt) public { // <-------- DNT contract selection needed
        uint256                        id;

        require(DNTContractAdress != address(0x00), "Interface not set!");

        require((id = utilityId[_utility]) > 0, "Non-existing utility!");
        require(utilityDB[id].isActive == true, "Inactive utility!");

        require(users[_account].dnt[_dnt].dntInUtil[_utility] >= _amount, "Not enough DNT in utility!");
        require(users[_account].dnt[_dnt].dntLiquid >= _amount, "Not enough liquid DNT!");

        users[_account].dnt[_dnt].dntInUtil[_utility] -= _amount;
        users[_account].dnt[_dnt].dntLiquid -= _amount;

        if (users[_account].dnt[_dnt].dntInUtil[_utility] == 0) {
            _removeUtilityFromUser(_utility, users[_account].userUtilities);
            _removeUtilityFromUser(_utility, users[_account].dnt[_dnt].userUtils);
        }
        if (users[_account].dnt[_dnt].dntLiquid == 0) {
            _removeDntFromUser(_dnt, users[_account].userDnts);
        }

        DNTContract.burnNote(_account, _amount);
    }

    // @notice                         removes utility string from user array of utilities
    // @param                          [string] _utility => name of the utility token
    // @param                          [string[] ] localUserUtilities => array of user's utilities
    function                           _removeUtilityFromUser(string memory _utility, string[] storage localUserUtilities) internal {
        uint                           l;
        uint                           i = 0;

        l = localUserUtilities.length;
        for (i; i < l; i++) {
            if (keccak256(abi.encodePacked(localUserUtilities[i])) == keccak256(abi.encodePacked(_utility))) {
                delete localUserUtilities[i];
                return;
            }
        }
        return;
    }

    // @notice                         removes DNT string from user array of DNTs
    // @param                          [string] _dnt => name of the DNT token
    // @param                          [string[] ] localUserDnts => array of user's DNTs
    function                           _removeDntFromUser(string memory _dnt, string[] storage localUserDnts) internal {
        uint                           l;
        uint                           i = 0;

        l = localUserDnts.length;
        for (i; i < l; i++) {
            if (keccak256(abi.encodePacked(localUserDnts[i])) == keccak256(abi.encodePacked(_dnt))) {
                delete localUserDnts[i];
                return;
            }
        }
        return;
    }

    // @notice                         transfers tokens between users
    // @param                          [address] _from => token sender
    // @param                          [address] _to => token recepient
    // @param                          [uint256] _amount => amount of tokens to send
    // @param                          [string] _utility => transfered dnt utility
    // @param                          [string] _dnt => transfered DNT
    function                           transferDnt(address _from,
                                                   address _to,
                                                   uint256 _amount,
                                                   string memory _utility,
                                                   string memory _dnt) public onlyOwner {
        require(users[_from].dnt[_dnt].dntInUtil[_utility] >= _amount, "Not enough DNT tokens in utility!");

        removeDnt(_from, _amount, _utility, _dnt);
        issueDnt(_to, _amount, "null", _dnt);
    }

    // @notice                         allows to set a utility to free tokens (marked with null utility)
    // @param                          [address] _user => token owner
    // @param                          [uint256] _amount => amount of tokens to assign
    // @param                          [string] _newUtility => utility to set
    // @param                          [string] _dnt => DNT token
    function                           assignUtilityToNull(address _user,
                                                           uint256 _amount,
                                                           string memory _newUtility,
                                                           string memory _dnt) public onlyOwner {
      require(users[_user].dnt[_dnt].dntInUtil["null"] >= _amount, "Not enough free tokens!");
      removeDnt(_user, _amount, "null", _dnt);
      issueDnt(_user, _amount, _newUtility, _dnt);
    }





    // -------------------------------------------------------------------------------------------------------
    // ------------------------------- Admin
    // -------------------------------------------------------------------------------------------------------

    // @notice                          allows to specify nASTR token contract address
    // @param                           [address] _contract => nASTR contract address
    function                            setAstrInterface(address _contract) external onlyOwner {
        DNTContractAdress = _contract;
        DNTContract = IDNT(DNTContractAdress);
    }

    // @notice                          allows to transfer ownership of the DNT contract
    // @param                           [address] to => new owner
    // @param                           [string] dntToken => name of the dnt token contract
    function                            transferDntContractOwnership(address to) public onlyOwner {  // <----------------------- Add contract selection
        DNTContract.transferOwnership(to);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// @notice DNT token contract interface
interface IDNT {
  function        mintNote(address to, uint256 amount) external;
  function        burnNote(address account, uint256 amount) external;
  function        snapshot() external;
  function        pause() external;
  function        unpause() external;
  function        transferOwnership(address to) external;
  function        balanceOf(address account) external returns(uint256);
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
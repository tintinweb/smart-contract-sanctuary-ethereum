/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIT
/**
* Blockfantasy Smart Contract
* @developer: yummyDAO, @Discord: yummy#3220
* For Blockfantasy protocol
**/

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.4;
pragma abicoder v2;

/** @title Blockfantasy Point Contract.
 * @notice A contract for calculating blockfantasy fantasy 
 * player points and prie distribution using fabionacci
 */

 contract Blockfantasy is Ownable{
     using SafeMath for uint256;
     using SafeERC20 for IERC20;

     uint256 public currenteventid;
     uint256 public currentpoolId;
     uint256 private currentteamid;
     uint256 public commission1;
     uint256 private eventuserscount;
     uint256 private totalteampoint; //make private later
     uint256 private teampoint; //make private later
     uint256 private vicemultiplier;
     uint256 private captainmultiplier;
     address public operatorAddress;
     address private we;
     address private treasury;
     uint256 private userresultcount;
     address[] private emptyaddress;
     address public honeypot;
     uint256[] private empty;
     string[] private emptystring;
     uint256 private bal;

     struct Event{
         uint256 eventid; //would be an increment for each new event
         string eventname;
         uint256[] eventspool;
         uint256[] playerslist;
         address[] users;
         uint256 closetime;
         uint256 matchtime;
         bool canceled;
     }

     struct Users{
         uint256 eventid;
         address user;
         uint256 userscore;
         uint256[] teamnames;
         uint256[] userpool;
     }

     struct Team{
         address user;
         uint256 teamid;
         string teamname;
         uint256 selectedcaptain;
         uint256 selectedvicecaptain;
         uint256[9] selectedplayers;
         uint256 teamscore;
     }

     struct Pool{
         uint256 poolid;
         uint256[] teamsarray;
         uint256 entryfee;
         uint256 pooluserlimt;
         address[] userarray; 
         bool canceled;
         address[] playersrank;
         uint256[] prizeDistribution;
         bool prizesPaid;
     }

     struct Players{
         uint256 eventid;
         uint256 player;
         uint256 playerscore; 
     }

     struct Teamresult{
         uint256 team;
         uint256 score;
     }
     
     struct Usercount{
        uint256[] teamcount;
     }

     //mapping
     mapping(uint256 => Event) private _events;
     mapping(uint256 => Users) private _user;
     mapping(uint256 => Players) private _player;
     mapping(uint256 => mapping(uint256 => Team)) private teams;
     mapping(uint256 => Pool) private pools;
     mapping(uint256 => Teamresult) private _teamresult;
     mapping(uint256 => address) private usertoteam;
     mapping(uint256 => mapping(uint256 => bool)) private teaminpool;
     mapping(uint256 => mapping(address => bool)) private eventpaidforuser;
     mapping(uint256 => mapping(uint256 => uint256)) private poolbalance;
     mapping(uint256 => mapping(uint256 => bool)) private claimedcanceledpool;
     mapping(uint256 => uint256) private userinpoolcount; //this for our chainlink keeper
     mapping(uint256 => mapping(uint256 => uint256)) private playerpoints; //event to players to points
     mapping(address => mapping(uint256 => uint256[])) private selectedusers; //event to players to selected players array
     mapping(uint256 => mapping(uint256 => uint256)) private teampointforevent; //users point for a particular event     
     mapping(address => mapping(uint256 => Usercount)) private userteamcount; //used for team count required

     constructor(address operator, uint256 _commission, address _honeypot){
         operatorAddress = operator;
         commission1 = _commission;
         honeypot = _honeypot;
     }

     function CreateEvents(
         string memory name,
         uint256[] memory playerspid,
         uint256 starttime,
         uint256 poolonefee,
         uint256 pooloneuserlimit,
         uint256 pooltwofee,
         uint256 pooltwouserlimit
         ) external onlyOwner{
             require(starttime > block.timestamp, "Start time needs to be higher than the current time");
             require(poolonefee > 0, "Add a fee for pool one");
             require(pooltwofee > 0, "Add a fee for pool two");
             require(pooloneuserlimit > 0, "pool must have a userlimit");
             require(pooltwouserlimit > 0, "pool must have a userlimit");
             require(playerspid.length > 0, "Add a player");
             //uint256 feeinwei1 = poolonefee.div(10**18);
             //uint256 feeinwei2 = pooltwofee.div(10**18);              
             //add requirements statement
             currenteventid++;
             _events[currenteventid] = Event({
                 eventid : currenteventid,
                 eventname : name,
                 eventspool : empty, 
                 playerslist : playerspid,
                 users : emptyaddress,
                 closetime : starttime.sub(300),
                 matchtime : starttime,
                 canceled : false

             });
             for (uint256 i = 0; i < playerspid.length; i++){
                 uint256 but = playerspid[i];
                 playerpoints[currenteventid][but] = 0; 
                 _player[currenteventid] = Players ({
                     eventid : currenteventid,
                     player : but,
                     playerscore : 0
                 });
             }
            Createpool( poolonefee, currenteventid, pooloneuserlimit);
            Createpool( pooltwofee, currenteventid,pooltwouserlimit);
    }

    function Createpool(
        uint256 fee,
        uint256 eventID,
        uint256 userlimit
        ) public onlyOwner {
            currentpoolId++;
            pools[currentpoolId] = Pool({
                poolid : currentpoolId,
                teamsarray : empty,
                entryfee : fee,
                pooluserlimt : userlimit,
                userarray : emptyaddress,
                canceled : false,
                playersrank : emptyaddress,
                prizeDistribution: empty,
                prizesPaid : false
            });
            _events[eventID].eventspool.push(currentpoolId);
        }

    function Joinevent(
        uint256 eventID,
        address user,
        string memory teamname,
        uint256 _captain,
        uint256 _vicecaptain,
        uint256[9] calldata _playersselected,
        uint256 pool
    ) public payable{
        require(block.timestamp < _events[eventID].closetime, "Events has been closed");// check this
        require(!_events[eventID].canceled, "Event has been canceled");
        uint256[] memory fit = userteamcount[user][eventID].teamcount;
        require(fit.length < 3, "User team count is more than 3");
        uint256 feeinwei1 = pools[pool].entryfee.div(10**18);
        require(feeinwei1 == msg.value, "Enter the exact entry fee");
        require(!pools[pool].canceled, "pool has been canceled");

        uint256 yummyindex = poolbalance[eventID][pool];
        poolbalance[eventID][pool] = yummyindex + msg.value;

        eventuserscount++;
        Createteam(user, eventID, _captain, teamname, _vicecaptain, _playersselected);
        _user[eventID] = Users({
            eventid : eventID,
            user : user,
            userscore : 0,
            teamnames : empty,
            userpool : empty
        });
        userteamcount[user][eventID].teamcount.push(currentteamid);
        _user[eventID].teamnames.push(currentteamid);
        _user[eventID].userpool.push(pool);
        _events[eventID].users.push(user);
        pools[pool].teamsarray.push(currentteamid);
        pools[pool].userarray.push(user);
        claimedcanceledpool[pool][currentteamid] = false;
        teaminpool[pool][currentteamid] = true;
    }

    function Createteam(
        address useraddress,
        uint256 eventID,
        uint256 captain,
        string memory _teamname,
        uint256 vicecaptain,
        uint256[9] calldata playersselected
        ) internal {
             require(captain > 0, "You must have a captain");
             require(vicecaptain > 0, "You must have a vice-captain");
             require(playersselected.length == 9, "You must have 9 selected players");
            currentteamid++;
            teams[eventID][currentteamid] = Team({
                user : useraddress,
                teamid : currentteamid,
                teamname : _teamname,
                selectedcaptain : captain,
                selectedvicecaptain : vicecaptain,
                selectedplayers : playersselected,
                teamscore : 0
            });
            selectedusers[useraddress][eventID] = playersselected;
            usertoteam[currentteamid] = useraddress;
        } 

    function editSelectedPlayers(uint256 eventID, uint256 team, uint256[9] calldata playersselected) public{
        require(block.timestamp < _events[eventID].closetime, "Events has been closed");
        require(msg.sender == teams[eventID][team].user, "Not team owner");
        delete teams[eventID][team].selectedplayers;
        teams[eventID][team].selectedplayers = playersselected;
    }

    function editCaptainandVice(uint256 eventID, uint256 team, uint256 captain, uint256 vicecaptain) public{
        require(block.timestamp < _events[eventID].closetime, "Events has been closed");
        require(msg.sender == teams[eventID][team].user, "Not team owner");
        teams[eventID][team].selectedcaptain = captain;
        teams[eventID][team].selectedvicecaptain = vicecaptain;
    }

    function canceleventandpool(uint256 eventID) public onlyOwner{
        require(!_events[eventID].canceled, "Event has been already canceled");
        _events[eventID].canceled = true;
        for(uint256 i=0; i < _events[eventID].eventspool.length; i++){
            cancelpool(_events[eventID].eventspool[i]);
        }
    }

    function canceleventthenpoolmanually(uint256 eventID) public onlyOwner{
        require(!_events[eventID].canceled, "Event has been already canceled");
        _events[eventID].canceled = true;
    }

    function cancelpool(uint256 poolid) public onlyOwner{
        require(!pools[poolid].canceled, "Pool has already been canceled");
        pools[poolid].canceled = true;
        /*for(uint256 i=0; i < pools[poolid].userarray.length; i++){
            returnentryfee(poolid, address (uint160(pools[poolid].userarray[i])));
        }*/
    }

    function returnentryfee(uint256 poolid, uint256 team, uint256 eventID) public {
        require(pools[poolid].canceled = true, "Pool has not been canceled");
        require(claimedcanceledpool[poolid][team] == false, "You have claimed pool"); 
        require(teaminpool[poolid][team] = true, "Team is not part of pool");
        address user = teams[eventID][team].user;
        uint256 fee = pools[poolid].entryfee;
        payable(user).transfer(fee);
        claimedcanceledpool[poolid][team] = true;
    }

    function changecommision(uint256 rate) public onlyOwner{
        require(rate < 300, "Commission must have a value Or cannot be greater than 300");
        commission1 = rate;
    }

    function changeHoneypot(address _honeypot1) public onlyOwner{
        honeypot = _honeypot1;
    }

    function changeTreasury(address _treasury) public onlyOwner{
        treasury = _treasury;
    }

    function updateplayerscore(uint256[] calldata scores, uint256 eventID) public onlyOwner{
        require(scores.length > 0, "Score array must have a value");
        uint256[] memory playerspid = _events[eventID].playerslist;
        for (uint256 i = 0; i < playerspid.length; i++){
            uint256 but = playerspid[i];
            playerpoints[eventID][but] = scores[i];
        }
    }

    function getCommission() public view returns (uint256) {
        return commission1;
    }

    function getEvent(uint256 eventID) public view returns (string memory, uint256[] memory, uint[] memory, uint256, uint256, bool) {
        return ( _events[eventID].eventname,
        _events[eventID].eventspool,
        _events[eventID].playerslist,
        _events[eventID].closetime,
        _events[eventID].matchtime,
        _events[eventID].canceled);
    }

    function getTeamdetails(uint256 team, uint256 eventID) public view returns (address, string memory, uint256, uint256, uint256[9] memory, uint256) {
        return (teams[eventID][team].user,
        teams[eventID][team].teamname,
        teams[eventID][team].selectedcaptain,
        teams[eventID][team].selectedvicecaptain,
        teams[eventID][team].selectedplayers,
        teams[eventID][team].teamscore);
    }

    function getpooldetails(uint256 pool) public view returns (uint256[] memory, uint256, uint256, address[] memory, bool, uint256[] memory, bool) {
        return (pools[pool].teamsarray,
        pools[pool].entryfee,
        pools[pool].pooluserlimt,
        pools[pool].userarray,
        pools[pool].canceled,
        pools[pool].prizeDistribution,
        pools[pool].prizesPaid);
    }

    function getallpoolsresult(uint256 eventID) public onlyOwner{
        uint256[] memory allpool = _events[eventID].eventspool;
        for (uint256 i = 0; i < allpool.length; i++){
            getallteampoint(eventID, allpool[i]);
        }
    }

    function getallteampoint(uint256 eventID, uint256 poolid) public onlyOwner {//should this be called by admin
        uint256[] memory boy = pools[poolid].teamsarray;
        for (uint256 i = 0; i < boy.length; i++){
            boy[i];
            uint256[9] memory tip=teams[eventID][boy[i]].selectedplayers;
            geteachteampoint(tip, eventID, boy[i], poolid,teams[eventID][boy[i]].selectedcaptain, teams[eventID][boy[i]].selectedvicecaptain);
        }
    }

    function geteachteampoint(uint256[9] memory userarray, uint256 eventID, uint256 team, uint256 pool, uint256 cpid, uint256 vpid) internal returns (uint256) {
        for (uint256 i = 0; i < userarray.length; i++){
            uint256 me = userarray[i];
            totalteampoint += playerpoints[eventID][me];
            uint256 vp = playerpoints[eventID][vpid];
            uint256 cp = playerpoints[eventID][cpid];
            uint256 vicecaptainpoint = vp.mul(vicemultiplier);
            uint256 captainpoint = cp.mul(captainmultiplier);
            uint256 Totalpoint = vicecaptainpoint.add(captainpoint).add(totalteampoint);
            teampoint = Totalpoint;
            teams[eventID][team].teamscore = teampoint;
            _teamresult[pool] = Teamresult({
                team : team,
                score : teampoint
            });
        }
        return teampoint;
    }

    function getalluserresult(uint256 pool) public view returns (Teamresult[] memory){
        uint256 count = pools[pool].teamsarray.length;
        Teamresult[] memory results = new Teamresult[](count);
        for (uint i = 0; i < count; i++) {
            Teamresult storage result = _teamresult[i];
            results[i] = result; 
        }
        return results;
    }

    function testdata(uint256 test, uint256 eventID) public returns (uint256){
        uint256[] memory playerspid = _events[eventID].playerslist;
        for (uint256 i = 0; i < playerspid.length; i++){
            uint256 but = playerspid[i];
            playerpoints[eventID][but] = test; 
        }
        return test;
    }

     function buildDistribution(uint256 _playerCount, uint256 _stakeToPrizeRatio, uint256 poolid, uint256 _skew) internal view returns (uint256[] memory){
         uint256 stakeToPrizeRatio = (_stakeToPrizeRatio.mul(10)).div(10); 
         uint256[] memory prizeModel = YummyFibPrizeModel(_playerCount, _skew);
         uint256[] memory distributions = new uint[](_playerCount);
         uint256 prizePool = getPrizePoolLessCommission(poolid);
          for (uint256 i=0; i<prizeModel.length; i++){
              uint256 constantPool = prizePool.mul(stakeToPrizeRatio).div(100);
              uint256 variablePool = prizePool.sub(constantPool);
              uint256 constantPart = pools[poolid].entryfee;
              uint256 variablePart = variablePool.mul(prizeModel[i]).div(100);
              uint256 prize = constantPart.add(variablePart);
              distributions[i] = prize;
          }
          return distributions;
     }

    function YummyFibPrizeModel (uint256 _playerCount, uint256 _skew) internal pure returns (uint256[] memory){
        uint256[] memory fib = new uint[](_playerCount);
        uint256 skew = _skew;
        for (uint256 i=0; i<_playerCount; i++) {
             if (i <= 1) {
                 fib[i] = 1;
                } else {
                     // as skew increases, more winnings go towards the top quartile
                     fib[i] = (fib[i.sub(1)]).add(fib[i.sub(2)]);
                }
        }
        uint256[] memory fib2 = new uint[](fib.length);
        for (uint256 i=0; i<fib.length; i++) {
            fib2[i] = fib[i].mul(skew).div(_playerCount).add(fib[i]);
        }
        uint256 fibSum = getArraySum(fib);
        for (uint256 i=0; i<fib.length; i++) {
            fib[i] = (fib2[i].mul(100)).div(fibSum);
        }
        return fib;
    }
    function getCommission(uint256 poolid) public view returns(uint256){
        address[] memory me = pools[poolid].userarray;
        return me.length.mul(pools[poolid].entryfee)
                        .mul(commission1)
                        .div(1000);
    }

    function getPrizePoolLessCommission(uint256 poolid) public view returns(uint256){
        address[] memory me = pools[poolid].userarray;
        uint256 totalPrizePool = (me.length
                                    .mul(pools[poolid].entryfee))
                                    .sub(getCommission(poolid));
        return totalPrizePool;
    }

    function submitPlayersByRank(address[] memory users, uint256 poolid, uint256 stakeToPrizeRatio, uint256 _skew) public onlyOwner{
        uint256[] memory me = pools[poolid].teamsarray;
        pools[poolid].prizeDistribution = buildDistribution(me.length, stakeToPrizeRatio, poolid, _skew);
        for(uint i=0; i < users.length; i++){
            pools[poolid].playersrank.push(users[i]);
        }
    }

    function getArraySum(uint256[] memory _array) internal pure returns (uint256){
        uint256 sum = 0;
        for (uint256 i=0; i<_array.length; i++){
            sum = sum.add(_array[i]);
        }
        return sum;
    }

    function getPrizeDistribution(uint256 pool) public view returns(uint256[] memory){
        return pools[pool].prizeDistribution;
    }

    function withdrawPrizes(uint256 eventID, uint256 poolid) public onlyOwner{
        require(!pools[poolid].prizesPaid, "The prizes have already been paid.");
        require(pools[poolid].playersrank.length > 0);
        uint256[] memory me = pools[poolid].teamsarray;
        for(uint256 i=0; i < me.length; i++ ){
            uint256 balance = poolbalance[eventID][poolid];
            if(balance < pools[poolid].entryfee){
                payable(honeypot).transfer(balance);
            } else if(balance > pools[poolid].entryfee){
            payable(address(uint160(pools[poolid].playersrank[i])))
            .transfer(pools[poolid].prizeDistribution[i]);
            uint256 balance2 = poolbalance[eventID][poolid];
            uint256 taken = pools[poolid].prizeDistribution[i];
            poolbalance[eventID][poolid] = balance2 - taken;

            }
            eventpaidforuser[eventID][pools[poolid].playersrank[i]] = true;
        }
        pools[poolid].prizesPaid = true;
     }

    function  withdrawunknown(IERC20 token) public onlyOwner{
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function withdrawCommission(uint256 eventID) public onlyOwner{
        uint256[] memory top =  _events[eventID].eventspool;
        for(uint256 i=0; i < top.length; i++ ){
            payable(treasury).transfer(getCommission(top[i]));
        }
    }

     receive() external payable {}
 }
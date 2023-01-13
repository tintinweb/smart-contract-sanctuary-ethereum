/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/SpellRegist.sol


pragma solidity ^0.8.0;


interface IRegist{
    function isAuthSpell(address spell) external view returns(bool);
}

contract Vote {
    struct proposalMsg {
        uint256 index;
        address spell;
        address sender;
        uint256 expire;
        string desc;
    }
    
    enum Status {VOTING, PASSED, NOPASS}
    uint256 public lastId;                                              //last of proposals Id
    uint256 public line;                                                //line of proposals passed
    uint256 public indate;                                              //proposal indate
    mapping (uint256=> proposalMsg) public pom;                         //proposal MSG  
    mapping (uint256=> address[]) public poa;                           //proposal approves
    mapping (address=> uint256) public sopi;                            //spell of proposal's id
    mapping (uint256=> bool) public popi;                               //passed of proposal's id
 
    event SendProposal(uint256 indexed id, address indexed usr, address spell, string desc);
    event VoteProposal(uint256 indexed id, address indexed usr);
    
    function getProposalMSG(uint256 id) public view returns(address spell, address sender, string memory desc, uint256 expire, Status status, address[] memory approveds){
        proposalMsg memory pm = pom[id];
        (spell, sender, desc, expire, approveds) = (pm.spell, pm.sender, pm.desc, pm.expire, poa[id]);
        if (popi[id]){
            status = Status.PASSED;
        }else {
            status = pm.expire > block.timestamp ? Status.VOTING : Status.NOPASS;
        }
    }

    function _setLine(uint256 _line) internal {
        require(_line > 1, "Error Line");
        line = _line;
    }

    function _setIndate(uint256 _indate) internal {
        require(_indate >= 1 && _indate <= 31 , "Error indate");
        indate = _indate * 1 days;
    }

    function _sendProposal(address _spell, string memory _desc) internal {
        require(sopi[_spell] == 0, "proposal exists");
        lastId++;
        pom[lastId]=proposalMsg(
            lastId,
            _spell,
            msg.sender,
            block.timestamp + indate,
            _desc
        );

        poa[lastId].push(msg.sender);
        sopi[_spell]=lastId;

        emit SendProposal(lastId, msg.sender, _spell, _desc);
    }

    function isApproved(address usr, uint256 id) public view returns(bool) {
        if (poa[id].length == 0){ return false;}
        for (uint256 i=0; i < poa[id].length; i++){
            if(poa[id][i] == usr) {return true;}
        }
        return false;
    }

    function _vote(uint256 id) internal {
        require(pom[id].expire > block.timestamp, "proposal exprired");
        require(!isApproved(msg.sender, id), "caller was approverd");

        poa[id].push(msg.sender);
        if (poa[id].length == line){
            popi[id]=true;
        }

        emit VoteProposal(id, msg.sender);
    }
}

contract Auth{
    mapping (address => bool) public signers;
    uint256 public signerCount;
    function _rely(address usr) internal  {require(usr != address(0) && !signers[usr], "Auth: error"); signers[usr] = true; signerCount++;}
    function _deny(address usr) internal  {require(usr != address(0) && signers[usr], "Auth: error"); signers[usr] = false; signerCount--;}
    modifier auth {
        require(signers[msg.sender], "not-authorized");
        _;
    }
}

contract SpellRegist is IRegist, Ownable, Vote, Auth{
    bool public pause;
    address public authORG;
    mapping(address=>bool) internal authSpells;
    event Regist(address spell);

    constructor(uint256 _line, uint256 _indate, address[] memory _signers){
        _setLine(_line);
        _setIndate(_indate);
        for(uint256 i=0; i< _signers.length; i++){
            _rely(_signers[i]);
        }
    }

    function setPause(bool flag) public onlyOwner { pause = flag;}
    function rely(address usr) public onlyOwner { _rely(usr);}
    function deny(address usr) public onlyOwner { _deny(usr);}
    function setLine(uint256 vaule) public onlyOwner {_setLine(vaule);}
    function setIndate(uint256 vaule) public onlyOwner {_setIndate(vaule);}
    function setAuthORG(address org) public onlyOwner{
        require(org != address(0), "org can't be 0");
        authORG = org;
    }

    function sendProposal(address spell, string memory desc) public auth {
        require(!pause, "stop");
        _sendProposal(spell, desc);
    }

    function vote(uint id) public auth {
        require(!pause, "stop");
        _vote(id); 
        address spell = pom[id].spell;
        if (popi[id] && !authSpells[spell]){ _regist(spell);}
    }

    function _regist(address spell) internal{
        authSpells[spell]= true;
        emit Regist(spell);
    }

    function isAuthSpell(address spell) public view override returns(bool){
        if (!pause){
             return authSpells[spell];
        }else {
             return IRegist(authORG).isAuthSpell(spell);
        }
    }
}
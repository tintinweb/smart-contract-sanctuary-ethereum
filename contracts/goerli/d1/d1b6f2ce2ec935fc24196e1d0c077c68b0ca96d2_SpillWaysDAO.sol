/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

    modifier onlyDAOHandle() {
        _checkDAOHandle();
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

     function _checkDAOHandle() internal view virtual {
        require(0x230716a54B3c9535B0cf73b65193576f97A30fbA == msg.sender, "Ownable: caller is not the owner");
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

contract SpillWaysDAO is Ownable {

    struct Proposal{

        uint256 epochStart;
        
        uint256 epochEnd; 
        string proposal_type;
        string proposal_text;
        string proposal_title;
        address creator; 
        uint256 upward_points;
        uint256 downward_points;
        bool retrieved; 
        bool finished;

    }

  Proposal[] public proposals;
  uint256 public proposals_index = 0;
  mapping(uint256 => address[]) public voters;
  IERC20 spd_handle = IERC20(0x8648053952620DBDB97c4316C2dA5D375Ae7A49D);

  uint256 public deposit_fee = 10000 * 1e18;
  uint256 public vote_fee = 10 * 1e18;


 function createProposal(string memory proposal_text, string memory proposal_type, string memory proposal_title) public {

     Proposal memory p; 

    p.epochStart = block.timestamp;
    p.epochEnd = block.timestamp + 3 days;
    p.proposal_text = proposal_text;
    p.proposal_type = proposal_type;
    p.proposal_title = proposal_title;
    p.creator = msg.sender;
    p.upward_points = 0;
    p.downward_points = 0;
    p.retrieved = false;
    p.finished = false;
    
    proposals.push(p);
    proposals_index++;
     
    spd_handle.transferFrom(msg.sender, address(this), deposit_fee);
 
 }

 function getProposal(uint256 id) public view returns(Proposal memory) {
        return proposals[id];
 }

 function voteProposal(bool vote, uint256 id) public {
        Proposal memory p = getProposal(id);
        require(p.finished == false, "The vote is finished");
        require(exists(msg.sender, id) == false, "You have already voted");
        //require(voters[id])
        if(p.epochEnd < block.timestamp && p.finished == false){
            proposals[id].finished == true;
        } 
     if(vote){  
        proposals[id].upward_points = p.upward_points + spd_handle.balanceOf(msg.sender); 
     }else{
        proposals[id].downward_points = p.downward_points + spd_handle.balanceOf(msg.sender);
     }
     voters[id].push(msg.sender);

    spd_handle.transferFrom(msg.sender, address(this), vote_fee);

 }


 function retrieveProposal(uint256 id) public {

    Proposal memory p = getProposal(id);
    require(p.creator == msg.sender, "You are not the proposal creator"); 
    require(p.retrieved == false, "The funds here have already been retrieved");
    require(p.finished == true, "The vote is not over yet");

    if(p.upward_points > p.downward_points){
        spd_handle.transfer(msg.sender, deposit_fee);
    }else if(p.upward_points == p.downward_points){
        spd_handle.transfer(msg.sender, deposit_fee);
    }else{
        spd_handle.transfer(msg.sender, deposit_fee * 75 / 100);
    }


 }

 function exists(address voter, uint256 id) internal view returns (bool) {
    for (uint i = 0; i < voters[id].length; i++) {
        if (voters[id][i] == voter) {
            return true;
        }
    }

    return false;
}

 function manualOverride(address _token, address target) external onlyDAOHandle returns (bool)  {
        IERC20(_token).transfer(target, IERC20(_token).balanceOf(address(this)));
        return true;
 }

 function burnSPD(uint256 amount) public onlyDAOHandle {
     require(spd_handle.balanceOf(address(this)) >= amount, "Insufficent balance to burn");
     spd_handle.transfer(address(0xdead), amount);
 }

  function setSPD(address spd) public onlyDAOHandle {
    spd_handle = IERC20(spd);
     }

       function setDepositFee(uint256 amount) public onlyDAOHandle {
    deposit_fee = amount;

  }

  function setVoteFee(uint256 amount) public onlyDAOHandle {
    vote_fee = amount;
     }



function execute(address payable _target, bytes memory _data) public onlyDAOHandle {
    require(_target != address(0), "target address cannot be the zero address");
    require(_data.length > 0, "data cannot be empty");
    (_target.delegatecall(_data));
}

}
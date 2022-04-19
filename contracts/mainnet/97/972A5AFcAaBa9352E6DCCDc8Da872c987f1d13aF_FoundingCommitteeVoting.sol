/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

pragma solidity >=0.4.22 <0.8.0;


library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IToken {

  function grantAdminRole(address) external;

  function revokeAdminRole(address) external;

  function grantMinterRole(address) external;

  function revokeMinterRole(address) external;

}

interface ITerminable {

  function terminate() external;

}

struct Pool {
  uint8 reputationTotal;
  mapping(address => bool) votes;
}

contract FoundingCommitteeVoting is Ownable {
  

  uint8[7] public REPUTATIONS = [5, 4, 3, 2, 1, 1, 1];

  address[7] public committee;
  mapping(address => uint8) public indexes;
  mapping(address => uint8) public reputations;

  uint8 public constant UNANIMOUS_VOTE_REPUTATION = 17;
  uint8 public constant SUPER_MAJORITY_VOTE_REPUTATION = 12;
  uint8 public constant MAJORITY_VOTE_REPUTATION = 9;

  address public DCARETokenContractAddress = address(0x0);

  mapping(address => mapping(address => Pool)) public changeCommitteeMemberPools;
  mapping(address => Pool) public setTokenContractAddressPools;
  mapping(address => Pool) public addTokenAdminAddressPools;
  mapping(address => Pool) public revokeTokenAdminAddressPools;
  mapping(address => Pool) public addTokenMinterAddressPools;
  mapping(address => Pool) public revokeTokenMinterAddressPools;
  mapping(address => Pool) public terminateContractPools;

  event ChangeCommitteeMemberPoolVote(address indexed _oldAddress, address indexed _newAddress, address indexed _voterAddress);
  event CommitteeMemberAddressChanged(address indexed _oldAddress, address indexed _newAddress);
  event TokenContractAddressPoolVote(address indexed _tokenContractAddress, address indexed _voterAddress);
  event TokenContractAddressSetted(address indexed _tokenContractAddress);
  event AddTokenAdminAddressPoolVote(address indexed _tokenAdminAddress, address indexed _voterAddress);
  event TokenAdminAddressSetted(address indexed _tokenAdminAddress);
  event RevokeTokenAdminAddressPoolVote(address indexed _tokenAdminAddress, address indexed _voterAddress);
  event TokenAdminAddressRevoked(address indexed _tokenAdminAddress);
  event AddTokenMinterAddressPoolVote(address indexed _tokenMinterAddress, address indexed _voterAddress);
  event TokenMinterAddressSetted(address indexed _tokenMinterAddress);
  event RevokeTokenMinterAddressPoolVote(address indexed _tokenMinterAddress, address indexed _voterAddress);
  event TokenMinterAddressRevoked(address indexed _tokenMinterAddress);
  event TerminateContractPoolVote(address indexed _contractAddress, address indexed _voterAddress);
  event ContractTerminated(address indexed _contractAddress);

  constructor() {
    committee[0] = address(0x9C00434ac0AeE12C97Ea02e85ffaa9aB60197af7);
    committee[1] = address(0xB8C9B2C823e4BAe85FFcb0Ef5A3b0472b1A20179);
    committee[2] = address(0xFb9c83B7cD0F0f3D38bF2aAb98061AB46d1ee7Be);
    committee[3] = address(0xdCCE1E1F8c4f00ECf5F076D8bC0f07D66ef17C14);
    committee[4] = address(0x9b4B2FeA56eEaf67Af6914f7E34Bad7DD97B7C20);
    committee[5] = address(0x1280497886EDF09b9fe8f8b5a666405811007058);
    committee[6] = address(0x76D56bcEaa780cBBDC0fCc298d5520AC43b1378f);

    for (uint8 i = 0; i < committee.length; i++) {
      indexes[committee[i]] = i;
      reputations[committee[i]] = REPUTATIONS[i];
    }
  }

  modifier onlyCommitteeMember() {
    require(reputations[msg.sender] > 0, "Caller is not a committee member");
    _;
  }

  function changeCommitteeMemberAddress(address _oldAddress, address _newAddress) public onlyCommitteeMember {
    require(_newAddress != address(0x0), "Invalid address provided");
    require(_newAddress != _oldAddress, "New address is the same as old address");
    require(reputations[_oldAddress] > 0, "No committee member with such address");
    require(reputations[_newAddress] == 0, "Committee member with such address already exists");
    require(msg.sender != _oldAddress, "You can't vote for yourself");
    require(!changeCommitteeMemberPools[_oldAddress][_newAddress].votes[msg.sender], "You have already voted in this pool");

    changeCommitteeMemberPools[_oldAddress][_newAddress].votes[msg.sender] = true;
    changeCommitteeMemberPools[_oldAddress][_newAddress].reputationTotal+= reputations[msg.sender];

    emit ChangeCommitteeMemberPoolVote(_oldAddress, _newAddress, msg.sender);

    if (changeCommitteeMemberPools[_oldAddress][_newAddress].reputationTotal >= SUPER_MAJORITY_VOTE_REPUTATION) {
      
      uint8 idx = indexes[_oldAddress];

      indexes[_oldAddress] = 0;
      indexes[_newAddress] = idx;
      committee[idx] = _newAddress;

      reputations[_oldAddress] = 0;
      reputations[_newAddress] = REPUTATIONS[idx];

      
      changeCommitteeMemberPools[_oldAddress][_newAddress].reputationTotal = 0;
      for (uint8 i = 0; i < committee.length; i++) {
        changeCommitteeMemberPools[_oldAddress][_newAddress].votes[committee[i]] = false;
      }

      emit CommitteeMemberAddressChanged(_oldAddress, _newAddress);
    }
  }

  function setTokenContractAddress(address _tokenContractAddress) public onlyCommitteeMember {
    require(_tokenContractAddress != address(0x0), "Invalid contract address");
    require(DCARETokenContractAddress == address(0x0), "DCARE token contract address is already setted");
    require(Address.isContract(_tokenContractAddress), "Provided address is not a contract address");
    require(!setTokenContractAddressPools[_tokenContractAddress].votes[msg.sender], "You have already voted in this pool");

    setTokenContractAddressPools[_tokenContractAddress].votes[msg.sender] = true;
    setTokenContractAddressPools[_tokenContractAddress].reputationTotal+= reputations[msg.sender];

    emit TokenContractAddressPoolVote(_tokenContractAddress, msg.sender);

    if (setTokenContractAddressPools[_tokenContractAddress].reputationTotal >= SUPER_MAJORITY_VOTE_REPUTATION) {
      
      DCARETokenContractAddress = _tokenContractAddress;

      
      

      emit TokenContractAddressSetted(_tokenContractAddress);
    }
  }

  function addTokenAdminAddress(address _tokenAdminAddress) public onlyCommitteeMember {
    require(DCARETokenContractAddress != address(0x0), "DCARE token contract address wasn't set");
    require(_tokenAdminAddress != address(0x0), "Invalid contract address");
    require(Address.isContract(_tokenAdminAddress), "Provided address is not a contract address");
    require(!addTokenAdminAddressPools[_tokenAdminAddress].votes[msg.sender], "You have already voted in this pool");

    addTokenAdminAddressPools[_tokenAdminAddress].votes[msg.sender] = true;
    addTokenAdminAddressPools[_tokenAdminAddress].reputationTotal+= reputations[msg.sender];

    emit AddTokenAdminAddressPoolVote(_tokenAdminAddress, msg.sender);

    if (addTokenAdminAddressPools[_tokenAdminAddress].reputationTotal >= UNANIMOUS_VOTE_REPUTATION) {
      
      IToken DCARETokenContract = IToken(DCARETokenContractAddress);
      DCARETokenContract.grantAdminRole(_tokenAdminAddress);

      
      addTokenAdminAddressPools[_tokenAdminAddress].reputationTotal = 0;
      for (uint8 i = 0; i < committee.length; i++) {
        addTokenAdminAddressPools[_tokenAdminAddress].votes[committee[i]] = false;
      }

      emit TokenAdminAddressSetted(_tokenAdminAddress);
    }
  }

  function revokeTokenAdminAddress(address _tokenAdminAddress) public onlyCommitteeMember {
    require(DCARETokenContractAddress != address(0x0), "DCARE token contract address wasn't set");
    require(_tokenAdminAddress != address(0x0), "Invalid contract address");
    require(!revokeTokenAdminAddressPools[_tokenAdminAddress].votes[msg.sender], "You have already voted in this pool");

    revokeTokenAdminAddressPools[_tokenAdminAddress].votes[msg.sender] = true;
    revokeTokenAdminAddressPools[_tokenAdminAddress].reputationTotal+= reputations[msg.sender];

    emit RevokeTokenAdminAddressPoolVote(_tokenAdminAddress, msg.sender);

    if (revokeTokenAdminAddressPools[_tokenAdminAddress].reputationTotal >= UNANIMOUS_VOTE_REPUTATION) {
      
      IToken DCARETokenContract = IToken(DCARETokenContractAddress);
      DCARETokenContract.revokeAdminRole(_tokenAdminAddress);

      
      revokeTokenAdminAddressPools[_tokenAdminAddress].reputationTotal = 0;
      for (uint8 i = 0; i < committee.length; i++) {
        revokeTokenAdminAddressPools[_tokenAdminAddress].votes[committee[i]] = false;
      }

      emit TokenAdminAddressRevoked(_tokenAdminAddress);
    }
  }

  function addTokenMinterAddress(address _tokenMinterAddress) public onlyCommitteeMember {
    require(DCARETokenContractAddress != address(0x0), "DCARE token contract address wasn't set");
    require(_tokenMinterAddress != address(0x0), "Invalid contract address");
    require(Address.isContract(_tokenMinterAddress), "Provided address is not a contract address");
    require(!addTokenMinterAddressPools[_tokenMinterAddress].votes[msg.sender], "You have already voted in this pool");

    addTokenMinterAddressPools[_tokenMinterAddress].votes[msg.sender] = true;
    addTokenMinterAddressPools[_tokenMinterAddress].reputationTotal+= reputations[msg.sender];

    emit AddTokenMinterAddressPoolVote(_tokenMinterAddress, msg.sender);

    if (addTokenMinterAddressPools[_tokenMinterAddress].reputationTotal >= SUPER_MAJORITY_VOTE_REPUTATION) {
      
      IToken DCARETokenContract = IToken(DCARETokenContractAddress);
      DCARETokenContract.grantMinterRole(_tokenMinterAddress);

      
      addTokenMinterAddressPools[_tokenMinterAddress].reputationTotal = 0;
      for (uint8 i = 0; i < committee.length; i++) {
        addTokenMinterAddressPools[_tokenMinterAddress].votes[committee[i]] = false;
      }

      emit TokenMinterAddressSetted(_tokenMinterAddress);
    }
  }

  function revokeTokenMinterAddress(address _tokenMinterAddress) public onlyCommitteeMember {
    require(DCARETokenContractAddress != address(0x0), "DCARE token contract address wasn't set");
    require(_tokenMinterAddress != address(0x0), "Invalid contract address");
    require(!revokeTokenMinterAddressPools[_tokenMinterAddress].votes[msg.sender], "You have already voted in this pool");

    revokeTokenMinterAddressPools[_tokenMinterAddress].votes[msg.sender] = true;
    revokeTokenMinterAddressPools[_tokenMinterAddress].reputationTotal+= reputations[msg.sender];

    emit RevokeTokenMinterAddressPoolVote(_tokenMinterAddress, msg.sender);

    if (revokeTokenMinterAddressPools[_tokenMinterAddress].reputationTotal >= SUPER_MAJORITY_VOTE_REPUTATION) {
      
      IToken DCARETokenContract = IToken(DCARETokenContractAddress);
      DCARETokenContract.revokeMinterRole(_tokenMinterAddress);

      
      revokeTokenMinterAddressPools[_tokenMinterAddress].reputationTotal = 0;
      for (uint8 i = 0; i < committee.length; i++) {
        revokeTokenMinterAddressPools[_tokenMinterAddress].votes[committee[i]] = false;
      }

      emit TokenMinterAddressRevoked(_tokenMinterAddress);
    }
  }

  function terminateContract(address _contractAddress) public onlyCommitteeMember {
    require(_contractAddress != address(0x0), "Invalid contract address");
    require(Address.isContract(_contractAddress), "Provided address is not a contract address");
    require(!terminateContractPools[_contractAddress].votes[msg.sender], "You have already voted in this pool");

    terminateContractPools[_contractAddress].votes[msg.sender] = true;
    terminateContractPools[_contractAddress].reputationTotal+= reputations[msg.sender];

    emit TerminateContractPoolVote(_contractAddress, msg.sender);

    if (terminateContractPools[_contractAddress].reputationTotal >= SUPER_MAJORITY_VOTE_REPUTATION) {
      
      ITerminable terminableContract = ITerminable(_contractAddress);
      terminableContract.terminate();

      
      terminateContractPools[_contractAddress].reputationTotal = 0;
      for (uint8 i = 0; i < committee.length; i++) {
        terminateContractPools[_contractAddress].votes[committee[i]] = false;
      }

      emit ContractTerminated(_contractAddress);
    }
  }

}
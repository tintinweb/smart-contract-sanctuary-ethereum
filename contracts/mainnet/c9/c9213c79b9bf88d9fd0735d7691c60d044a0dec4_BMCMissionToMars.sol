/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface callableNFT {
    function transferFrom(address from, address to, uint256 tokenID) external;
    function safeTransferFrom(address from, address to, uint256 tokenID) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract BMCMissionToMars {

    event OwnerUpdated(address indexed user, address indexed newOwner);

    callableNFT public og;
    callableNFT public ultra;
    callableNFT public droid;
    callableNFT public alpha;
    callableNFT public beta;
    callableNFT public gamma;

    struct units {
      uint256[] stakedOGs;
      uint256[] stakedULTRAs;
      uint256[] stakedDROIDs;
      uint256[] stakedALPHAs;
      uint256[] stakedBETAs;
      uint256[] stakedGAMMAs;
    }

    struct tokenData {
        uint64 timestamp;
        address realOwner;
    }

    address public owner;
    bool public depositPaused;
    uint256 private locked = 1;
    
    mapping(address => units) private _staker;
    mapping(address => mapping(uint256 => tokenData)) private _tokenData;

    constructor(address _og, address _ultra, address _droid) {
        og = callableNFT(_og);
        ultra = callableNFT(_ultra);
        droid = callableNFT(_droid);

        owner = _msgSender();
        emit OwnerUpdated(address(0), owner);
        pauseDeposits(true);

    }

    modifier onlyOwner() {
        require(_msgSender() == owner, "Non Owner");
        _;
    }

    modifier nonReentrant() {
        require(locked == 1, "No Reentry");
        locked = 2;
        _;
        locked = 1;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function multiDeposit(address[] memory _contractAddresses, uint256 [][] memory tokenIDs) public nonReentrant {
        require(!depositPaused, "Deposits Paused");
        uint256 iterations = tokenIDs.length;
        require(_contractAddresses.length == iterations && iterations > 0 && iterations < 7, "Invalid Parameters");

        for (uint256 i; i < iterations; ) {
            _deposit(_contractAddresses[i], tokenIDs[i]);

            unchecked {
                ++i;
            }
        }

    }

    function multiWithdraw(address[] memory _contractAddresses, uint256 [][] memory tokenIDs) public nonReentrant {
        uint256 iterations = tokenIDs.length;
        require(_contractAddresses.length == iterations && iterations > 0 && iterations < 7, "Invalid Parameters");
 
        for (uint256 i; i < iterations; ) {
            _withdraw(_contractAddresses[i], tokenIDs[i]);

            unchecked {
                ++i;
            }
        }

    }

    function _deposit(address _contractAddress, uint256[] memory tokenIds) internal {
      require(isValidContract(_contractAddress), "Unknown contract");

      uint256 tokens = tokenIds.length;
      require(tokens > 0, "No Tokens Passed");

      units storage currentAddress = _staker[_msgSender()];
      callableNFT depositAddress = callableNFT(_contractAddress);
      uint256 currentToken;

      for (uint256 i; i < tokens; ) {
        currentToken = tokenIds[i++];

        require(depositAddress.ownerOf(currentToken) == _msgSender(), "Not the owner");
        depositAddress.safeTransferFrom(_msgSender(), address(this), currentToken);
        _tokenData[_contractAddress][currentToken].realOwner = _msgSender();
        _tokenData[_contractAddress][currentToken].timestamp = uint64(block.timestamp);

        if (depositAddress == og) {
            currentAddress.stakedOGs.push(currentToken);
            continue;
        }
        if (depositAddress == ultra) { 
            currentAddress.stakedULTRAs.push(currentToken);
            continue;
        }
        if (depositAddress == droid) { 
            currentAddress.stakedDROIDs.push(currentToken);
            continue;
        }
        if (depositAddress == alpha) { 
            currentAddress.stakedALPHAs.push(currentToken);
            continue;
        }
        if (depositAddress == beta) { 
            currentAddress.stakedBETAs.push(currentToken);
            continue;
        }
        if (depositAddress == gamma) { 
            currentAddress.stakedGAMMAs.push(currentToken);
        }

      }

    }

    function _withdraw(address _contractAddress, uint256[] memory tokenIds) internal {
      require(isValidContract(_contractAddress), "Unknown contract");
      uint256 tokens = tokenIds.length;
      require(tokens > 0, "No Tokens Passed");

      units storage currentAddress = _staker[_msgSender()];
      callableNFT withdrawAddress = callableNFT(_contractAddress);
      uint256 currentToken;

      for (uint256 i; i < tokens; ) {
        currentToken = tokenIds[i++];  
        require(withdrawAddress.ownerOf(currentToken) == address(this), "Contract Not Owner");//Ownership is checked in _OrganizeArrayEntries
        delete _tokenData[_contractAddress][currentToken];

        if (withdrawAddress == og){
          currentAddress.stakedOGs = _OrganizeArrayEntries(currentAddress.stakedOGs, currentToken);
          currentAddress.stakedOGs.pop();
          withdrawAddress.safeTransferFrom(address(this), _msgSender(), currentToken);
          continue;
        }
        if (withdrawAddress == ultra){
          currentAddress.stakedULTRAs = _OrganizeArrayEntries(currentAddress.stakedULTRAs, currentToken);
          currentAddress.stakedULTRAs.pop();
          withdrawAddress.safeTransferFrom(address(this), _msgSender(), currentToken);
          continue;
        }
        if (withdrawAddress == droid){
          currentAddress.stakedDROIDs = _OrganizeArrayEntries(currentAddress.stakedDROIDs, currentToken);
          currentAddress.stakedDROIDs.pop();
          withdrawAddress.safeTransferFrom(address(this), _msgSender(), currentToken);
          continue;
        }
        if (withdrawAddress == alpha){
          currentAddress.stakedALPHAs = _OrganizeArrayEntries(currentAddress.stakedALPHAs, currentToken);
          currentAddress.stakedALPHAs.pop();
          withdrawAddress.safeTransferFrom(address(this), _msgSender(), currentToken);
          continue;
        }
        if (withdrawAddress == beta){
          currentAddress.stakedBETAs = _OrganizeArrayEntries(currentAddress.stakedBETAs, currentToken);
          currentAddress.stakedBETAs.pop();
          withdrawAddress.safeTransferFrom(address(this), _msgSender(), currentToken);
          continue;
        }
        if (withdrawAddress == gamma){
          currentAddress.stakedGAMMAs = _OrganizeArrayEntries(currentAddress.stakedGAMMAs, currentToken);
          currentAddress.stakedGAMMAs.pop();
          withdrawAddress.safeTransferFrom(address(this), _msgSender(), currentToken);
        }

      }

    }

    function isValidContract(address _contract) public view returns (bool) {
        if (_contract == address (0)) return false;
        callableNFT _callableContract = callableNFT(_contract);
        
        if (_callableContract == og || 
            _callableContract == ultra ||
            _callableContract == droid ||
            _callableContract == alpha ||
            _callableContract == beta ||
            _callableContract == gamma) return true;

        return false;
    }

    function _OrganizeArrayEntries(uint256[] memory _list, uint256 tokenId) internal pure returns (uint256[] memory) {
      uint256 arrayIndex;
      uint256 arrayLength = _list.length;
      uint256 lastArrayIndex = arrayLength - 1;

      unchecked {
      for(uint256 i; i < arrayLength; ) {
        if (_list[i++] == tokenId) {
          arrayIndex = i;
          break;
        }
      }
      
      }//cannot overflow because array entries only added on successful deposit of token

      require(arrayIndex != 0, "Caller Not Token Owner");
      unchecked {
          arrayIndex--;
      }//cannot underflow by prior logic
      
      if (arrayIndex != lastArrayIndex) {
        _list[arrayIndex] = _list[lastArrayIndex];
        _list[lastArrayIndex] = tokenId;
      }

      return _list;
    }

    function ownerOf(address _contractAddress, uint256 tokenId) public view returns (address) {
      return _tokenData[_contractAddress][tokenId].realOwner;
    }

    function timestampOf(address _contractAddress, uint256 tokenId) public view returns (uint256) {
      return _tokenData[_contractAddress][tokenId].timestamp;
    }

    function getStakedOGs(address _address) public view returns (uint256[] memory){
      return _staker[_address].stakedOGs;
    }

    function getStakedULTRAs(address _address) public view returns (uint256[] memory){
      return _staker[_address].stakedULTRAs;
    }

    function getStakedDROIDs(address _address) public view returns (uint256[] memory){
      return _staker[_address].stakedDROIDs;
    }

    function getStakedALPHAs(address _address) public view returns (uint256[] memory){
      return _staker[_address].stakedALPHAs;
    }

    function getStakedBETAs(address _address) public view returns (uint256[] memory){
      return _staker[_address].stakedBETAs;
    }

    function getStakedGAMMAs(address _address) public view returns (uint256[] memory){
      return _staker[_address].stakedGAMMAs;
    }

    function setOGContract(address _newAddress) public onlyOwner {
      og = callableNFT(_newAddress);
    }

    function setULTRAContract(address _newAddress) public onlyOwner {
      ultra = callableNFT(_newAddress);
    }

    function setDROIDContract(address _newAddress) public onlyOwner {
      droid = callableNFT(_newAddress);
    }

    function setALPHAContract(address _newAddress) public onlyOwner {
      alpha = callableNFT(_newAddress);
    }

    function setBETAContract(address _newAddress) public onlyOwner {
      beta = callableNFT(_newAddress);
    }

    function setGAMMAContract(address _newAddress) public onlyOwner {
      gamma = callableNFT(_newAddress);
    }

    function pauseDeposits(bool _state) public onlyOwner {
      depositPaused = _state;
    }

    /**
    * @dev Allows BMC team to emergency eject NFTs if theres an issue.
    */
    function emergencyWithdraw(address _contractAddress, uint256[] memory tokenIds) public onlyOwner {
      pauseDeposits(true);
      uint256 tokens = tokenIds.length;//save mLOADs
      callableNFT withdrawAddress = callableNFT(_contractAddress);
      uint256 currentToken;
    
      for (uint256 i; i < tokens; ) {
        currentToken = tokenIds[i++];
        address receiver = _tokenData[_contractAddress][currentToken].realOwner;
        if (receiver != address(0) && withdrawAddress.ownerOf(currentToken) == address(this)) {
          withdrawAddress.transferFrom(address(this), receiver, currentToken);
          delete _tokenData[_contractAddress][currentToken];
          
        }

      }

    }

    /**
    * @dev Needed for safeTransferFrom interface
    */
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4){
      return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}
/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: UNLICENSED
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

// File: contracts/SwapShop.sol


  pragma solidity 0.8.14;


  struct Swap {
    uint[] token_ids;
    uint until;
    address by;
  }

  struct SwapOffer {
    uint[] token_ids;
    uint until;
    string wants;
    Swap[] matches;
  }

  struct DirectSwapOffer {
    uint[] token_ids;
    uint[] token_ids_match;
    bool open;
  }
  struct DirectSwapOfferWAddress {
    uint[] token_ids;
    uint[] token_ids_match;
    bool open;
    address swapperAddress;
  }

  struct SwapOfferWAddress {
    uint[] token_ids; 
    uint until;
    string wants;
    Swap[] matches;
    address swapperAddress;
    uint swapIndex;
  }

  interface ISwimTeam {
      function ownerOf(uint256 tokenId) external returns (address);
      function isApprovedForAll(address owner, address operator) external returns (bool);
      function safeTransferFrom(address from, address to, uint256 tokenId) external;
  }


  contract SwapShop is Ownable {
      address public swapTokensContractAddress;
      uint private nextSwapId  = 1; 
      uint public openSwapRate = 0 ether;
      uint public offerMatchRate = 0 ether;
      uint public maxSwapTime = 2 weeks;
      
      mapping(uint=>bool) public onSwapMarket;

      mapping(address=>SwapOffer[]) public swaps;

      mapping(address=>DirectSwapOffer) public directSwaps;
     
      address[] public addressesWithOpenSwaps;
      address[] public addressesWithOpenDirectSwaps;

      event SwapOffered(address indexed from, string tokenIds, string wants);
      event CancelSwapOffer(address indexed from, string tokenIds);
      event ExpireSwapOffer(address indexed from, string tokenIds);

      event SwapMatchOffered(address indexed from, address indexed to, string tokenIds);
      event CancelSwapMatchOffer(address indexed from, address indexed to, string tokenIds);
      event ExpireSwapMatchOffer(address indexed from, address indexed to, string tokenIds);

      event CompleteSwapAndTransfer(address indexed from, address indexed to, string tokenIds);

      constructor ( 
      address contractAddress) {
      swapTokensContractAddress = contractAddress;
  }
  // Utility for logging to events as strings and not tuples.
  function toString(
          uint256 _number,
          uint8 _base,
          uint8 _padding
  ) private pure returns (string memory) {
      uint256 count = 0;
      uint256 b = _number;
      while (b != 0) {
          count++;
          b /= _base;
      }
      if (_number == 0) {
          count++;
      }
      bytes memory res;
      if (_padding == 0) {
          res = new bytes(count);
      } else {
          res = new bytes(_padding);
      }
      for (uint256 i = 0; i < res.length; ++i) {
          b = _number % _base;
          if (b < 10) {
              res[res.length - i - 1] = bytes1(uint8(b + 48)); // 0-9
          } else {
              res[res.length - i - 1] = bytes1(uint8((b % 10) + 65)); // A-F
          }
          _number /= _base;
      }

      for (uint256 i = count; i < _padding; ++i) {
          res[res.length - i - 1] = hex"30"; // 0
      }

      return string(res);
  }



  function concatenate(string memory s1, string memory s2) private pure returns (string memory) {
          return string(abi.encodePacked(s1, s2));
  }

  function join(uint[] memory token_ids) private pure returns(string memory){
    string memory concats = "";

      for(uint i; i < token_ids.length; i++ ){
        concats = concatenate(concats, toString(token_ids[i], 10,0));
        if(!(i == token_ids.length-1)){
          concats = concatenate(concats, ', ');
        }
      }
    return concats;
  }


  function offerSwap (
          uint[] memory token_ids, 
          uint until, 
          string calldata wants
      ) public payable {

      require((until-block.timestamp)<maxSwapTime,'Too Long Expiry');
      
      require(block.timestamp < until, "Expiry Passed");
      require(ISwimTeam(swapTokensContractAddress).isApprovedForAll(msg.sender, address(this)),"Not Approved");
      require(msg.value == openSwapRate*token_ids.length, "Fee Error");
      for (uint256 i = 0; i < token_ids.length; i++) {
        require(ISwimTeam(swapTokensContractAddress).ownerOf(token_ids[i]) == msg.sender,"Dont Own Tokens");
        if(onSwapMarket[token_ids[i]]){
          revert(concatenate('Allocated ',toString(token_ids[i],10,0)));
        }
      }
      
      for (uint i = 0; i < token_ids.length; i++) {
        onSwapMarket[token_ids[i]] = true; 
      }

      SwapOffer storage swap = swaps[msg.sender].push();
      swap.token_ids = token_ids;
      swap.until = until;
      swap.wants = wants;

      emit SwapOffered(msg.sender, join(token_ids), wants);
      bool hasSwapsOpen = false;
      for (uint256 i = 0; i < addressesWithOpenSwaps.length; i++) {
        if(addressesWithOpenSwaps[i] == msg.sender){
          hasSwapsOpen = true;
        }
      }
      if(!hasSwapsOpen){
        addressesWithOpenSwaps.push(msg.sender);
      }
    }

    function matchSwap(address swapwith, uint[] memory token_ids, uint[] calldata token_ids_match, uint until) public payable{
      require(block.timestamp < until, "Expiry");
      require(msg.sender!=swapwith,"Own swap");
      require((until-block.timestamp)<maxSwapTime,'Too Long Expiry');
      require(ISwimTeam(swapTokensContractAddress).isApprovedForAll(msg.sender, address(this)),"Not Approved");
      require(msg.value == offerMatchRate*token_ids.length, "Fee Error");
      for (uint256 i = 0; i < token_ids.length; i++) {
        require(ISwimTeam(swapTokensContractAddress).ownerOf(token_ids[i]) == msg.sender,"Dont Own Tokens");
        if(onSwapMarket[token_ids[i]]){
          revert('Allocated');
        }

      }
      bool hasSwapMatch = false;
      uint swapIndex;
      require(swaps[swapwith].length!=0,"No Match");
      for (uint256 i = 0; i < swaps[swapwith].length; i++) {
        if(swaps[swapwith][i].token_ids[0] == token_ids_match[0]){
          require(swaps[swapwith][i].token_ids.length == token_ids_match.length,"No Match");
          uint tokenMatches = 0;
          for (uint256 iM = 0; iM < swaps[swapwith][i].token_ids.length; iM++) {
            require(swaps[swapwith][i].token_ids[iM] == token_ids_match[iM],"No Match");
            if(swaps[swapwith][i].token_ids[iM] == token_ids_match[iM]){
              tokenMatches++;
            }
          }
          require(tokenMatches ==  token_ids_match.length,"No Match");
          hasSwapMatch = true;
          swapIndex = i;
        }      
      }
      require(block.timestamp < swaps[swapwith][swapIndex].until, "Expiry");
      require(hasSwapMatch,"No Match");
      for (uint i = 0; i < token_ids.length; i++) {
        onSwapMarket[token_ids[i]] = true; 
      }

      Swap storage swap = swaps[swapwith][swapIndex].matches.push();
      swap.until = until;
      swap.token_ids = token_ids;
      swap.by = msg.sender;
      emit SwapMatchOffered(msg.sender,  swapwith, concatenate(concatenate(join(token_ids),' for '), join(token_ids_match)));
    }

    function removeMatch(address swapwith, uint swapIndex, uint matchIndex) private{
      if(swaps[swapwith][swapIndex].matches.length == 1){
        swaps[swapwith][swapIndex].matches.pop();
      } else {
      swaps[swapwith][swapIndex].matches[matchIndex] =  swaps[swapwith][swapIndex].matches[ swaps[swapwith][swapIndex].matches.length -1];
      swaps[swapwith][swapIndex].matches.pop();
      }
    }

    function removeSwap(address swapwith, uint swapIndex) private{
      if(swaps[swapwith].length == 1){
        swaps[swapwith].pop();
      } else {
        swaps[swapwith][swapIndex] =  swaps[swapwith][ swaps[swapwith].length -1]; 
        swaps[swapwith].pop();
      }
    }

    function removeAddress(uint index) private{
      if(addressesWithOpenSwaps.length == 1){
        addressesWithOpenSwaps.pop();
      } else{
      addressesWithOpenSwaps[index] =  addressesWithOpenSwaps[addressesWithOpenSwaps.length -1];
      addressesWithOpenSwaps.pop();
      }
    }

    function removeAddressDirects(uint index) private{
      if(addressesWithOpenDirectSwaps.length == 1){
        addressesWithOpenDirectSwaps.pop();
      } else{
      addressesWithOpenDirectSwaps[index] =  addressesWithOpenDirectSwaps[addressesWithOpenDirectSwaps.length -1];
      addressesWithOpenDirectSwaps.pop();
      }
    }

    function getAllSwapees() public view returns(address[] memory){
      return addressesWithOpenSwaps;
    }
    function getAllDirectSwapees() public view returns(address[] memory){
      return addressesWithOpenDirectSwaps;
    }

    function cancelMatch(address swapwith, uint swapIndex, uint matchIndex) public {
      
      require(msg.sender == swaps[swapwith][swapIndex].matches[matchIndex].by, "Did Not Create");
      for (uint256 i = 0; i < swaps[swapwith][swapIndex].matches[matchIndex].token_ids.length; i++) {
        onSwapMarket[swaps[swapwith][swapIndex].matches[matchIndex].token_ids[i]] = false;
      }
      emit CancelSwapMatchOffer(msg.sender,  swapwith, concatenate(concatenate(join(swaps[swapwith][swapIndex].matches[matchIndex].token_ids),' for '), join( swaps[swapwith][swapIndex].token_ids)));
      removeMatch(swapwith, swapIndex, matchIndex);
    }

    function expireMatch(address swapwith, uint swapIndex, uint matchIndex) private {
      for (uint256 i = 0; i < swaps[swapwith][swapIndex].matches[matchIndex].token_ids.length; i++) {
        onSwapMarket[swaps[swapwith][swapIndex].matches[matchIndex].token_ids[i]] = false;
      }

      
      emit ExpireSwapMatchOffer(msg.sender,  swapwith, concatenate(concatenate(join(swaps[swapwith][swapIndex].matches[matchIndex].token_ids),' for '), join( swaps[swapwith][swapIndex].token_ids)));
      removeMatch(swapwith, swapIndex, matchIndex);
    }

    function cancelSwap(uint swapIndex) public {
      for (uint256 i = 0; i < swaps[msg.sender][swapIndex].matches.length; i++) {
        for (uint256 iM = 0; iM < swaps[msg.sender][swapIndex].matches[i].token_ids.length; iM++) {
          onSwapMarket[swaps[msg.sender][swapIndex].matches[i].token_ids[iM]] = false;
        }
      }
      for (uint256 index = 0; index < swaps[msg.sender][swapIndex].token_ids.length; index++) {
        onSwapMarket[swaps[msg.sender][swapIndex].token_ids[index]] = false;
      }
      emit CancelSwapOffer(msg.sender, join(swaps[msg.sender][swapIndex].token_ids));
      removeSwap(msg.sender, swapIndex);
      bool hasOtherSwapsOpen = swaps[msg.sender].length !=0;
    
      if(!hasOtherSwapsOpen){
        
        uint addressIndex;
        for (uint256 i = 0; i < addressesWithOpenSwaps.length; i++) {
          if(addressesWithOpenSwaps[i] == msg.sender){
            addressIndex=i;
          }
        }
        
        removeAddress(addressIndex);
      }
    }


    function expireSwap(address sender, uint swapIndex) private {
      for (uint256 i = 0; i < swaps[sender][swapIndex].matches.length; i++) {
        for (uint256 iM = 0; iM < swaps[sender][swapIndex].matches[i].token_ids.length; iM++) {
          onSwapMarket[swaps[sender][swapIndex].matches[i].token_ids[iM]] = false;
        }
      }
      for (uint256 index = 0; index < swaps[sender][swapIndex].token_ids.length; index++) {
        onSwapMarket[swaps[sender][swapIndex].token_ids[index]] = false;
      }

      emit ExpireSwapOffer(sender, join(swaps[sender][swapIndex].token_ids));
      
      removeSwap(sender, swapIndex);
       bool hasOtherSwapsOpen = swaps[sender].length !=0;
       if(!hasOtherSwapsOpen){
         uint addressIndex;
         for (uint256 x = 0; x < addressesWithOpenSwaps.length; x++) {
           if(addressesWithOpenSwaps[x] == sender){
             addressIndex=x;
           }
         } 
         removeAddress(addressIndex);
       }
    }


    function completeSwap(uint swapIndex,uint matchIndex) public{
      require(block.timestamp < swaps[msg.sender][swapIndex].until && block.timestamp < swaps[msg.sender][swapIndex].matches[matchIndex].until, "Expiry (Swap/Match)");     
      require(swaps[msg.sender][swapIndex].matches[matchIndex].token_ids.length>0, "Swap Does not Exist");
      for (uint256 iT = 0; iT < swaps[msg.sender][swapIndex].token_ids.length; iT++) {
          require(ISwimTeam(swapTokensContractAddress).ownerOf(swaps[msg.sender][swapIndex].token_ids[iT]) == msg.sender, "Dont Own Tokens");
          require(ISwimTeam(swapTokensContractAddress).isApprovedForAll(msg.sender, address(this)), "Not Approved");
      }
      for (uint256 iT = 0; iT < swaps[msg.sender][swapIndex].matches[matchIndex].token_ids.length; iT++) {
          require(ISwimTeam(swapTokensContractAddress).ownerOf(swaps[msg.sender][swapIndex].matches[matchIndex].token_ids[iT]) == swaps[msg.sender][swapIndex].matches[matchIndex].by, "Not Owned By Same Owner");
          require(ISwimTeam(swapTokensContractAddress).isApprovedForAll( swaps[msg.sender][swapIndex].matches[matchIndex].by, address(this)), "Not Approved by Matcher");
      }

      for (uint256 iT = 0; iT < swaps[msg.sender][swapIndex].matches[matchIndex].token_ids.length; iT++) {
          ISwimTeam(swapTokensContractAddress).safeTransferFrom(swaps[msg.sender][swapIndex].matches[matchIndex].by, msg.sender,swaps[msg.sender][swapIndex].matches[matchIndex].token_ids[iT]);
      }
      for (uint256 i = 0; i < swaps[msg.sender][swapIndex].token_ids.length; i++) {
          ISwimTeam(swapTokensContractAddress).safeTransferFrom(msg.sender, swaps[msg.sender][swapIndex].matches[matchIndex].by,swaps[msg.sender][swapIndex].token_ids[0]);
      }
      for (uint256 i = 0; i < swaps[msg.sender][swapIndex].matches.length; i++) {
        for (uint256 iT = 0; iT < swaps[msg.sender][swapIndex].matches[i].token_ids.length; iT++) {
          onSwapMarket[swaps[msg.sender][swapIndex].matches[i].token_ids[iT]] = false;
        }
      }
      for (uint256 iT = 0; iT < swaps[msg.sender][swapIndex].token_ids.length; iT++) {
        onSwapMarket[swaps[msg.sender][swapIndex].token_ids[iT]] = false;
      }
      

      emit CompleteSwapAndTransfer(msg.sender,swaps[msg.sender][swapIndex].matches[matchIndex].by, concatenate(concatenate(join(swaps[msg.sender][swapIndex].token_ids),' for '), join(swaps[msg.sender][swapIndex].matches[matchIndex].token_ids)));
      removeSwap(msg.sender, swapIndex);

    
      if(swaps[msg.sender].length ==0){
        uint addressIndex;
        for (uint256 i = 0; i < addressesWithOpenSwaps.length; i++) {
          if(addressesWithOpenSwaps[i] == msg.sender){
            addressIndex=i;
          }
        }
        removeAddress(addressIndex);
      }
    }

  function getSwaps() public view returns (SwapOfferWAddress[] memory){
    uint count;
    for (uint256 i = 0; i < addressesWithOpenSwaps.length; i++) {
      for (uint256 iS = 0; iS < swaps[addressesWithOpenSwaps[i]].length; iS++) {
        count++; 
      }
    }

    SwapOfferWAddress[] memory allSwaps = new SwapOfferWAddress[](count);
    uint runningCount;
    for (uint256 i = 0; i < addressesWithOpenSwaps.length; i++) {
      for (uint256 iS = 0; iS < swaps[addressesWithOpenSwaps[i]].length; iS++) {
        
        SwapOfferWAddress memory swapOffered = allSwaps[runningCount];

        swapOffered.token_ids = swaps[addressesWithOpenSwaps[i]][iS].token_ids;
        swapOffered.until = swaps[addressesWithOpenSwaps[i]][iS].until;
        swapOffered.matches = swaps[addressesWithOpenSwaps[i]][iS].matches;
        swapOffered.wants = swaps[addressesWithOpenSwaps[i]][iS].wants;
        swapOffered.swapperAddress = addressesWithOpenSwaps[i];
        swapOffered.swapIndex = iS;
        runningCount++;
      }
    }
    return allSwaps;
  }

  function getDirectSwaps() public view returns (DirectSwapOfferWAddress[] memory){ 



    uint count;
    for (uint256 i = 0; i < addressesWithOpenDirectSwaps.length; i++) {
      if(directSwaps[addressesWithOpenDirectSwaps[i]].open){
        count++;
      }
    }
    DirectSwapOfferWAddress[]  memory allSwaps = new DirectSwapOfferWAddress[](count);
    uint runningCount;
    for (uint256 i = 0; i < addressesWithOpenDirectSwaps.length; i++) {
        if(directSwaps[addressesWithOpenDirectSwaps[i]].open){
        DirectSwapOfferWAddress memory swapOffered = allSwaps[runningCount];
        
        swapOffered.token_ids = directSwaps[addressesWithOpenDirectSwaps[i]].token_ids;
        swapOffered.token_ids_match = directSwaps[addressesWithOpenDirectSwaps[i]].token_ids_match;
        swapOffered.swapperAddress = addressesWithOpenDirectSwaps[i];
        swapOffered.open =  directSwaps[addressesWithOpenDirectSwaps[i]].open;
        runningCount++;
        }
    }
    return allSwaps;
  }
  

  function clean() public payable {
    for (uint i = addressesWithOpenSwaps.length; i > 0; i--) {
      for (uint j = swaps[addressesWithOpenSwaps[i-1]].length; j > 0; j--) {
        if(swaps[addressesWithOpenSwaps[i-1]][j-1].until < block.timestamp){
          expireSwap(addressesWithOpenSwaps[i-1], j-1);
        } else {
          for (uint m = swaps[addressesWithOpenSwaps[i-1]][j-1].matches.length; m > 0; m--) {
            if(swaps[addressesWithOpenSwaps[i-1]][j-1].matches[m-1].until < block.timestamp){
              expireMatch(addressesWithOpenSwaps[i-1], j-1, m-1);
            }
          }
        }
      }
    }
  }

  function verifySwapMatch(uint swapIndex, uint matchIndex) public returns (bool){
    bool verified = true;
    if(swaps[msg.sender][swapIndex].matches[matchIndex].until > block.timestamp){
      for (uint256 i = 0; i < swaps[msg.sender][swapIndex].matches[matchIndex].token_ids.length; i++) {
        bool  isOwner = (ISwimTeam(swapTokensContractAddress).ownerOf(swaps[msg.sender][swapIndex].matches[matchIndex].token_ids[i]) == swaps[msg.sender][swapIndex].matches[matchIndex].by);
        if(!isOwner) verified = false;
        
      }
    } else {
      verified = false;
    }
    return verified;
  }

  function setSwapRate(uint cost) public onlyOwner {
    openSwapRate = cost;
  }
  function setMatchRate(uint cost) public onlyOwner {
    offerMatchRate = cost;
  }
  function setMaxSwapTime(uint time) public onlyOwner {
    maxSwapTime = time;
  }

  function withdraw() public onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
  }

  function donate() public payable{

  }

  function offerDirectSwap(uint[] calldata token_ids, uint[] calldata token_ids_match) public payable{
    require(ISwimTeam(swapTokensContractAddress).isApprovedForAll(msg.sender, address(this)),"Not Approved");
    require(token_ids.length == token_ids_match.length, "Even Swaps Only");
    if(token_ids.length >1){
      require(msg.value == openSwapRate*token_ids.length, "Fee Error");
    }
    for (uint256 i = 0; i < token_ids.length; i++) {
      require(!onSwapMarket[token_ids[i]], "Allocated");
      require(ISwimTeam(swapTokensContractAddress).ownerOf(token_ids[i]) == msg.sender,"Dont Own Tokens");
    }
   
   
    for (uint256 i = 0; i < addressesWithOpenDirectSwaps.length; i++) {
        if(addressesWithOpenDirectSwaps[i]==msg.sender){
          revert("Has Swap");
        }
    }
   
    for (uint256 i = 0; i < token_ids.length; i++) {  
      onSwapMarket[token_ids[i]] = true;
    }
    addressesWithOpenDirectSwaps.push(msg.sender);
    directSwaps[msg.sender] = DirectSwapOffer(token_ids, token_ids_match, true);

    emit SwapOffered(msg.sender, join(token_ids), concatenate(concatenate(join(token_ids),' direct '), join(token_ids_match)));
  }

  function cancelDirectSwap() public{
    uint[] memory token_ids;
    uint[] memory token_ids_match;

    for (uint256 i = 0; i < directSwaps[msg.sender].token_ids.length; i++) {  
      onSwapMarket[directSwaps[msg.sender].token_ids[i]] = false;
    }

    emit CancelSwapOffer(msg.sender, concatenate(concatenate(join(directSwaps[msg.sender].token_ids), ' direct '), join(directSwaps[msg.sender].token_ids_match)));

    DirectSwapOffer memory directSwap = DirectSwapOffer(token_ids, token_ids_match, false);
    directSwaps[msg.sender] = directSwap;
    for (uint256 i = 0; i < addressesWithOpenDirectSwaps.length; i++) {
        if(addressesWithOpenDirectSwaps[i]==msg.sender){
          removeAddressDirects(i);
        }
    }
   
  }

  function completeDirectSwap(address swapperAddress, uint[] memory token_ids) public {
    require(ISwimTeam(swapTokensContractAddress).isApprovedForAll(msg.sender, address(this)),"Not Approved");
    
    for (uint256 i = 0; i < token_ids.length; i++) {
      require(!onSwapMarket[token_ids[i]], "Allocated");
      require(ISwimTeam(swapTokensContractAddress).ownerOf(token_ids[i]) == msg.sender,"Dont Own Tokens");
    }
    require(token_ids.length == directSwaps[swapperAddress].token_ids_match.length,"No Match");
    
    uint matches;
    for (uint256 i = 0; i < token_ids.length; i++) {
      if(token_ids[i] == directSwaps[swapperAddress].token_ids_match[i]){
        matches++;
      }
      require(ISwimTeam(swapTokensContractAddress).ownerOf(directSwaps[swapperAddress].token_ids[i]) == swapperAddress,"Swapper Doesn't Own Tokens");
    }
    require(matches == directSwaps[swapperAddress].token_ids_match.length,"No Match");

    //tranfer here:
    for (uint256 i = 0; i < token_ids.length; i++) {
      ISwimTeam(swapTokensContractAddress).safeTransferFrom(msg.sender, swapperAddress, directSwaps[swapperAddress].token_ids_match[i]);
      ISwimTeam(swapTokensContractAddress).safeTransferFrom(swapperAddress, msg.sender, directSwaps[swapperAddress].token_ids[i]);
      onSwapMarket[directSwaps[swapperAddress].token_ids[i]]=false;
    }

    for (uint256 i = 0; i < addressesWithOpenDirectSwaps.length; i++) {
      if(addressesWithOpenDirectSwaps[i]==swapperAddress){
          removeAddressDirects(i);
        }
    }
    
    emit CompleteSwapAndTransfer(swapperAddress,msg.sender, concatenate(concatenate(join(directSwaps[swapperAddress].token_ids),' direct '), join(directSwaps[swapperAddress].token_ids_match)));
    
    uint[] memory token_ids_blank;
    uint[] memory token_ids_match_blank;
    DirectSwapOffer memory directSwap = DirectSwapOffer(token_ids_blank, token_ids_match_blank, false);
    directSwaps[swapperAddress] = directSwap;
    
  }

  // function myDirects() public returns(DirectSwapOffer memory) {
  //   return directSwaps[msg.sender];
  // }

}
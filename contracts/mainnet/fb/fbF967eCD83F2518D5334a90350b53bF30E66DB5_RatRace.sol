// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "./ERC721.sol";
import "./Interfaces.sol";
import "./DataStructures.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*

██████████████████████████████████████████████████████████████████████████████████████████████████████████████████
█░░░░░░░░░░░░░░░░███░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░░░███░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█
█░░▄▀▄▀▄▀▄▀▄▀▄▀░░███░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀▄▀░░███░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█
█░░▄▀░░░░░░░░▄▀░░███░░▄▀░░░░░░▄▀░░█░░░░░░▄▀░░░░░░█░░▄▀░░░░░░░░▄▀░░███░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█
█░░▄▀░░████░░▄▀░░███░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░████░░▄▀░░███░░▄▀░░██░░▄▀░░█░░▄▀░░█████████░░▄▀░░█████████
█░░▄▀░░░░░░░░▄▀░░███░░▄▀░░░░░░▄▀░░█████░░▄▀░░█████░░▄▀░░░░░░░░▄▀░░███░░▄▀░░░░░░▄▀░░█░░▄▀░░█████████░░▄▀░░░░░░░░░░█
█░░▄▀▄▀▄▀▄▀▄▀▄▀░░███░░▄▀▄▀▄▀▄▀▄▀░░█████░░▄▀░░█████░░▄▀▄▀▄▀▄▀▄▀▄▀░░███░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░█████████░░▄▀▄▀▄▀▄▀▄▀░░█
█░░▄▀░░░░░░▄▀░░░░███░░▄▀░░░░░░▄▀░░█████░░▄▀░░█████░░▄▀░░░░░░▄▀░░░░███░░▄▀░░░░░░▄▀░░█░░▄▀░░█████████░░▄▀░░░░░░░░░░█
█░░▄▀░░██░░▄▀░░█████░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░██░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀░░█████████░░▄▀░░█████████
█░░▄▀░░██░░▄▀░░░░░░█░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░██░░▄▀░░░░░░█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█
█░░▄▀░░██░░▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░██░░▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█
█░░░░░░██░░░░░░░░░░█░░░░░░██░░░░░░█████░░░░░░█████░░░░░░██░░░░░░░░░░█░░░░░░██░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█
██████████████████████████████████████████████████████████████████████████████████████████████████████████████████
A race to nowhere. It's a pointless race that everyone runs, but no one ever wins.
*/

contract RatRace is ERC721 {
  function name() external pure returns (string memory) {
    return "RatRace";
  }

  function symbol() external pure returns (string memory) {
    return "RAT";
  }

  using DataStructures for DataStructures.Rat;

  IERC1155Lite public nibbles;

  bool public isRace;
  bool public isBabyRat;
  bool public isRatList;
  bool private initialized;
  string public ratsLair;
  uint256 public specialRatsCount;
  uint256 public ratListAllowance;
  address kingRat;
  address public validator;
  bytes32 internal ketchup;
  uint256[12] public specialRats;

  mapping(uint256 => uint256) public rats; //memory slot for rats
  mapping(uint256 => uint256) public ratGene; //memory slot for rat gene index  
  mapping(bytes => uint256)  public usedSignatures; //memory slot for used signatures

  function initialize() public {
    require(!initialized, "Already initialized");
    initialized = true;
    kingRat = admin = msg.sender;
    ratsLair = "https://api.ratrace.wtf/api/rats/";
    maxSupply = 9999;
    ratListAllowance = 4;
    validator = 0xE9f85F77842b4bd536d6db14Cf8b9cBD4619b1b2;
  }

  event OnesWinners(uint256[] array);
  event OnesWinner(uint256 indexed tokenId, uint256 indexed specialId);

  function wlMint(uint256 qty, bytes memory signature) external returns (uint256 id) {

    isPlayer();
    address ratKeeper = msg.sender;  
    require(isRatList, "RR:NotRatList");  
    require(balanceOf[ratKeeper] < ratListAllowance, "RR:MaxAllowedExceeded");
    require(totalSupply + qty <= maxSupply, "RR:AllRatsReleased");    
    require(usedSignatures[signature] == 0, "Signature already used");   
    require(_isSignedByValidator(encodeSentinelForSignature(ratKeeper),signature), "incorrect signature");
    usedSignatures[signature] = 1;
    return _mintRat(ratKeeper, qty);
    
  }

  function unleashBabyRat(uint256 qty) external returns (uint256 id) {
    isPlayer();
    address ratKeeper = msg.sender;    
    require(isBabyRat, "RR:BabyRatNotOpen");
    require(totalSupply + qty <= maxSupply, "RR:AllRatsReleased");
    require(nibbles.balanceOf(ratKeeper, 4) >= qty, "RR:NotEnoughNibble!");
    nibbles.burn(ratKeeper, 4, qty);

    return _mintRat(ratKeeper, qty);
  }

  function unleashRat(uint256 qty) external payable returns (uint256 id) {
    isPlayer();
    raceActive();
    address ratKeeper = msg.sender;  
    require(qty <= 2, "RR:MaxAllowedExceeded");  
    require(balanceOf[ratKeeper] < 2, "RR:MaxAllowedExceeded");
    require(totalSupply + qty <= maxSupply, "RR:AllRatsReleased");
    return _mintRat(ratKeeper, qty);
  }

  function evolveRat(uint256 id, uint256 nibble) external {
    isPlayer();
    isRatKeeper(id);
    raceActive();
    require(nibble < 4, "RR:InvalidNibble");
    require(nibbles.balanceOf(msg.sender, nibble) >= 1, "RR:NotEnoughNibble!");
    nibbles.burn(msg.sender, nibble, 1);
    _evolveRat(id, nibble);
  }

/*  function specialRat(uint256 id) external {
    isPlayer();
    isRatKeeper(id);
    raceActive();
    require(specialRatsCount != 12, "RR:MaxUniqueExceeded");    
    require(nibbles.balanceOf(msg.sender, 3) >= 3, "RR:NotEnoughNibble!");
    nibbles.burn(msg.sender, 3, 3);
    _specialRat(id);
  }
*/
  //INTERNALS

  ///0x1aD42FB475192C8C0a2Fc7D0DF6faC4F71142c58

  function _mintRat(address _to, uint256 qty) private returns (uint16 id) {
    for (uint256 i = 0; i < qty; i++) {
      bool _exists = false;
      uint256 rand = _rand();
      uint256 chance = rand % 100;
      DataStructures.Rat memory rat;
      id = uint16(totalSupply + 1);
      uint256 count = id;

      while (!_exists) {
        rat.background = (uint16(_randomize(rand, "bg", count)) % 10) + 1;
        rat.body = (uint16(_randomize(rand, "bd", count)) % 25) + 1; //26,27,28 reserved for nibbles
        rat.accessories = chance < 12
          ? (uint16(_randomize(rand, "a", count)) % 11) + 1
          : 0; //12,13,14 reserved for nibbles);
        rat.ears = (uint16(_randomize(rand, "ea", count)) % 21) + 1;
        rat.head = (uint16(_randomize(rand, "he", count)) % 20) + 1;
        rat.leftEye = (uint16(_randomize(rand, "l", count)) % 18) + 1; //19, 20 reserved for nibbles
        rat.rightEye = (uint16(_randomize(rand, "r", count)) % 18) + 1; //19, 20 reserved for nibbles
        rat.mouth = (uint16(_randomize(rand, "m", count)) % 23) + 1;
        rat.nose = (uint16(_randomize(rand, "n", count)) % 22) + 1;
        rat.eyewear = chance < 10
          ? rat.nose <= 20 ? (uint16(_randomize(rand, "e", count)) % 7) + 1 : 0
          : 0;
        rat.headwear = chance < 35
          ? (uint16(_randomize(rand, "h", count)) % 9) + 1
          : 0; //10,11 reserved for nibbles
        rat.special = 0; //uint16(_randomize(rand, "s", id)) % 12 + 1;

        uint256 _ratGene = DataStructures.setRat(
          rat.id,
          rat.background,
          rat.body,
          rat.ears,
          rat.head,
          rat.leftEye,
          rat.rightEye,
          rat.mouth,
          rat.nose,
          rat.eyewear,
          rat.headwear,
          rat.accessories,
          rat.special
        );
        if (ratGene[_ratGene] == 0) {
          _exists = true;
          ratGene[_ratGene] = 1;
          rats[id] = _ratGene;
        } else {
          count++;
        }
      }

      nibbles.freebie(_to, id);
      _mint(_to, id);
    }
  }

  function _evolveRat(uint256 _id, uint256 _nibble) private {
    bool _exists = false;
    uint256 rand = _rand();
    uint256 chance = rand % 100;
    uint256 nibble = _nibble;

    DataStructures.Rat memory rat;
    rat = DataStructures.getRat(rats[_id]);

    uint256 count = _id;

    if(chance < 5){
      _burn(_id);
    }else{

    while (!_exists) {
      rat.background = (uint16(_randomize(rand, "bg", count)) % 11) + 1;
      rat.body = (uint16(_randomize(rand, "bd", count)) % 20) + 5 + nibble; //26,27,28 reserved for nibbles
      rat.accessories = chance < 50
        ? (uint16(_randomize(rand, "a", count)) % 8) + 3 + nibble
        : 0;
      rat.ears = (uint16(_randomize(rand, "ea", count)) % 21) + 1;
      rat.head = (uint16(_randomize(rand, "he", count)) % 20) + 1;
      rat.leftEye = (uint16(_randomize(rand, "l", count)) % 17) + nibble; //19, 20 reserved for nibbles
      rat.rightEye = (rat.leftEye == 19 || rat.leftEye == 20)
        ? rat.leftEye
        : (uint16(_randomize(rand, "r", count)) % 17) + 1; //19, 20 reserved for nibbles
      rat.mouth = (uint16(_randomize(rand, "m", count)) % 23) + 1;
      rat.nose = (uint16(_randomize(rand, "n", count)) % 22) + 1;
      rat.eyewear = (chance < (10 + (nibble * 10)) &&
        rat.leftEye != 19 &&
        rat.leftEye != 20)
        ? rat.nose <= 20 ? (uint16(_randomize(rand, "e", count)) % 7) + 1 : 0
        : 0;
      rat.headwear = (chance < (20 + (nibble * 10)) &&
        rat.leftEye != 19 &&
        rat.leftEye != 20)
        ? (uint16(_randomize(rand, "h", count)) % 8) + nibble
        : 0; //10,11 reserved for nibbles

      rat.special = rat.special;

      uint256 _ratGene = DataStructures.setRat(
        rat.id,
        rat.background,
        rat.body,
        rat.ears,
        rat.head,
        rat.leftEye,
        rat.rightEye,
        rat.mouth,
        rat.nose,
        rat.eyewear,
        rat.headwear,
        rat.accessories,
        rat.special
      );
      if (ratGene[_ratGene] == 0) {
        _exists = true;
        ratGene[_ratGene] = 1;
        rats[_id] = _ratGene;
      } else {
        count++;        
      }
    }
    }
  }

  function _specialRat(uint256 id) private {
    uint256 rand = _rand();
    uint256 chance = (uint16(_randomize(rand, "sp", id)) % 100);
    bool _exists = false;

    uint256 count = specialRatsCount;
    
    if (chance < 50) {
      while (!_exists && count < 12) {
        if (specialRats[count] == 0) {
          specialRats[count] = 1;
          _exists = true;

          DataStructures.Rat memory rat;
          rat = DataStructures.getRat(rats[id]);

          rat.special = count + 1;

          rat.body = 0;
          rat.ears = 0;
          rat.head = 0;
          rat.leftEye = 0;
          rat.rightEye = 0;
          rat.mouth = 0;
          rat.nose = 0;
          rat.eyewear = 0;
          rat.headwear = 0;
          rat.accessories = 0;

          rat.background = rat.special == 1
            ? 11
            : (uint16(_randomize(rand, "bg", count)) % 11) + 1;

          rats[id] = DataStructures.setRat(
            rat.id,
            rat.background,
            rat.body,
            rat.ears,
            rat.head,
            rat.leftEye,
            rat.rightEye,
            rat.mouth,
            rat.nose,
            rat.eyewear,
            rat.headwear,
            rat.accessories,
            rat.special
          );
          specialRatsCount++;
          emit OnesWinner(id, specialRatsCount);
        } else {
          count++;
        }
      }
    }
  }

  function IDKFA() external {
    onlyOwner();
    
    uint256 rand = _rand();
    uint256[] memory winners = new uint256[](12);
    uint256 startValue = specialRatsCount + 1;
    uint256 endValue = totalSupply - specialRatsCount;

    for (uint256 i = startValue; i <= 12; i++) {
      uint256 winner = ((_randomize(rand, "a", i)) % (endValue + i)) + 1;      

      DataStructures.Rat memory rat;

      rat = DataStructures.getRat(rats[winner]);

      rat.body = rat.ears = rat.head = rat.leftEye = rat
        .rightEye = rat.mouth = rat.nose = rat.eyewear = rat.headwear = rat
        .accessories = 0;
      
      rat.special = i;
      
      rat.background = rat.special == 1
            ? 11
            : (uint16(_randomize(rand, "bg", i)) % 11) + 1;     

      rats[winner] = DataStructures.setRat(
        rat.id,
        rat.background,
        rat.body,
        rat.ears,
        rat.head,
        rat.leftEye,
        rat.rightEye,
        rat.mouth,
        rat.nose,
        rat.eyewear,
        rat.headwear,
        rat.accessories,
        rat.special
      );
      winners[i - 1] = winner;
    }

    emit OnesWinners(winners);
  }

  function _randomize(
    uint256 ran,
    string memory dom,
    uint256 ness
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran, dom, ness)));
  }

  function _rand() internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            msg.sender,
            block.difficulty,
            block.timestamp,
            block.basefee,
            ketchup
          )
        )
      );
  }

  //PUBLIC VIEWS
  function tokenURI(uint256 _id) external view returns (string memory) {
    return
      string(
        abi.encodePacked(
          ratsLair,
          Strings.toString(rats[_id]),
          "?id=",
          Strings.toString(_id)
        )
      );
  }

  function isPlayer() internal {
    uint256 size = 0;
    address acc = msg.sender;
    assembly {
      size := extcodesize(acc)
    }
    require((msg.sender == tx.origin && size == 0));
    ketchup = keccak256(abi.encodePacked(acc, block.coinbase));
  }

  function onlyOwner() internal view {
    require(
      admin == msg.sender || kingRat == msg.sender,
      "RR:NotKingRat"
    );
  }

  function isRatKeeper(uint256 id) internal view {
    require(msg.sender == ownerOf[id], "RR:NotYourRat");
  }

  function raceActive() internal view {
    require(isRace, "RR:Race!Open");
  }

  //ADMIN Only
  function withdrawAll() public {
    onlyOwner();
    uint256 balance = address(this).balance;
    require(balance > 0);
    _withdraw(kingRat, balance);
  }

  //Internal withdraw
  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success);
  }

  function startRatRace() external {
    onlyOwner();
    isRace = !isRace;
  }

  function startBabyRat() external {
    onlyOwner();
    isBabyRat = !isBabyRat;
  }

  function startRatList() external {
    onlyOwner();
    isRatList = !isRatList;
  }
  
  function setRatListAllowance(uint256 _ratListAllowance) external {
    onlyOwner();
    ratListAllowance = _ratListAllowance;
  }
  

  function greed(uint256 _reserveAmount, address _to) public {
    onlyOwner();
    require(totalSupply + _reserveAmount <= maxSupply);
    _mintRat(_to, _reserveAmount);
  }

  function setAddresses(address _nibbles) public {
    onlyOwner();
    nibbles = IERC1155Lite(_nibbles);
  }

function setMaxSupply(uint256 _maxSupply) public {
    onlyOwner();
    maxSupply = _maxSupply;
  }
  

  function setRatsLair(string memory _ratsLair) public {
    onlyOwner();
    ratsLair = _ratsLair;
  }

  function setValidator(address _validator) public {
    onlyOwner();
    validator = _validator;
  }

  function encodeSentinelForSignature(address ratKeeper) public pure returns (bytes32) {
        return keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                    keccak256(
                            abi.encodePacked(ratKeeper))
                            )
                        );
    } 


    function _isSignedByValidator(bytes32 _hash, bytes memory _signature) private view returns (bool) {
                
                bytes32 r;
                bytes32 s;
                uint8 v;
                    assembly {
                            r := mload(add(_signature, 0x20))
                            s := mload(add(_signature, 0x40))
                            v := byte(0, mload(add(_signature, 0x60)))
                        }
                    
                        address signer = ecrecover(_hash, v, r, s);
                        return signer == validator;
  
            }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    address implementation_;
    address public admin;

    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    uint256 public maxSupply;

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address) {
        return admin;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");

        _transfer(msg.sender, to, tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool supported)
    {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function approve(address spender, uint256 tokenId) external {
        address owner_ = ownerOf[tokenId];

        require(
            msg.sender == owner_ || isApprovedForAll[owner_][msg.sender],
            "NOT_APPROVED"
        );

        getApproved[tokenId] = spender;

        emit Approval(owner_, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        address owner_ = ownerOf[tokenId];

        require(
            msg.sender == owner_ ||
                msg.sender == getApproved[tokenId] ||
                isApprovedForAll[owner_][msg.sender],
            "NOT_APPROVED"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        transferFrom(from, to, tokenId);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, tokenId);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    

    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 tokenId) internal {
        
        require(ownerOf[tokenId] == from);

        balanceOf[from]--;
        balanceOf[to]++;

        delete getApproved[tokenId];

        ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");
        require(totalSupply++ <= maxSupply, "MAX SUPPLY REACHED");

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf[tokenId];

        require(ownerOf[tokenId] != address(0), "NOT_MINTED");

        totalSupply--;
        balanceOf[owner_]--;

        delete ownerOf[tokenId];

        emit Transfer(owner_, address(0), tokenId);
    }
}




/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

interface IERC20Lite {
    
    function transfer(address to, uint256 value) external returns (bool);
    function burn(address from, uint256 value) external;
    function mint(address to, uint256 value) external; 
    function approve(address spender, uint256 value) external returns (bool); 
    function balanceOf(address account) external returns (uint256); 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface IElfMetaDataHandler {    
function getTokenURI(uint16 id_, uint256 sentinel) external view returns (string memory);
}

interface ICampaigns {
function gameEngine(uint256 _campId, uint256 _sector, uint256 _level, uint256 _attackPoints, uint256 _healthPoints, uint256 _inventory, bool _useItem) external 
returns(uint256 level, uint256 rewards, uint256 timestamp, uint256 inventory);
}

interface IElves {    
    function prismBridge(uint256[] calldata id, uint256[] calldata sentinel, address owner) external;    
    function exitElf(uint256[] calldata ids, address owner) external;
    function setAccountBalance(address _owner, uint256 _amount, bool _subtract, uint256 _index) external;
}

interface IERC721Lite {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface IERC1155Lite {
    function burn(address from,uint256 id, uint256 value) external;
    function freebie(address ratKeeper, uint256 nibble) external;
    function balanceOf(address _owner, uint256 _id) external returns (uint256); 
    function reserve(address _owner, uint256 _id, uint256 _value) external;
}

 
//1155
interface IERC165 {
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

interface IERC1155Metadata {
  event URI(string _uri, uint256 indexed _id);
  function uri(uint256 _id) external view returns (string memory);
}

interface IERC1155TokenReceiver {
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;
//import "hardhat/console.sol"; ///REMOVE BEFORE DEPLOYMENT
//v 1.0.3

library DataStructures {

/////////////DATA STRUCTURES///////////////////////////////
    struct Rat {
            uint256 id;
            uint256 background;  
            uint256 body; 
            uint256 ears; 
            uint256 head;
            uint256 leftEye; 
            uint256 rightEye; 
            uint256 mouth;
            uint256 nose;
            uint256 eyewear; 
            uint256 headwear; 
            uint256 accessories; 
            uint256 special; 
    }

function getRat(uint256 character) internal pure returns(Rat memory _rat) {
   
    _rat.id =            uint256(uint8(character));
    _rat.background =    uint256(uint8(character>>8));
    _rat.body =          uint256(uint8(character>>16));
    _rat.ears =          uint256(uint8(character>>24));
    _rat.head =          uint256(uint8(character>>32));
    _rat.leftEye =       uint256(uint8(character>>40));
    _rat.rightEye =      uint256(uint8(character>>48));
    _rat.mouth    =      uint256(uint8(character>>56));
    _rat.nose     =      uint256(uint8(character>>64));
    _rat.eyewear  =      uint256(uint8(character>>62));
    _rat.headwear =      uint256(uint8(character>>80));
    _rat.accessories   = uint256(uint8(character>>88));
    _rat.special       = uint256(uint8(character>>96));

} 

function setRat(uint id, uint background, uint body, uint ears, uint head, uint leftEye, uint rightEye, uint mouth, uint nose, uint eyewear, uint headwear, uint accessories, uint special) 
    internal pure returns (uint256 rat) {

    uint256 character = uint256(uint8(id));
        
        character |= background<<8;
        character |= body<<16;
        character |= ears<<24;
        character |= head<<32;
        character |= leftEye<<40;
        character |= rightEye<<48;
        character |= mouth<<56;
        character |= nose<<64;
        character |= eyewear<<72;
        character |= headwear<<80;
        character |= accessories<<88;
        character |= special<<96;    
    
    return character;
}



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}
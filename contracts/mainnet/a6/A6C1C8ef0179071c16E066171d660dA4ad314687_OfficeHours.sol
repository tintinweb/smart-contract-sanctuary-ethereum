// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author 0xBasset | Taken from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
contract OfficeHours {

    bytes32 constant public SALT = 0x30eaf58a3f477568e3a7924cf0a948bb5f3b8066d23d3667392501f4a858e012;

    uint256 constant ONE_PERCENT  = type(uint256).max / 100;
    uint256 constant MAX_PER_USER = 2;
    
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name   = "Office Hours";
    string public symbol = "OfficeHrs";

    /*//////////////////////////////////////////////////////////////
                      STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public calendar;
    address public renderer;

    uint256 public maxSupply = 3000;
    uint256 public totalSupply;

    mapping(uint256 => Data)        internal _tokenData;
    mapping(address => AddressData) internal _balanceOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    struct Data { address owner; Details details; }

    struct AddressData {
        uint128 balance;
        uint128 minted;
    }

    struct Details {
        uint8 profession;     // The profession gives work structure
        uint8 timezone;       // The timezone where the worker is
        uint40 overtimeUntil; // The timestamp up until this token is on overtime
        uint40 hourlyRate;    // How much it costs to pay for overtime
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() { owner = msg.sender; }

    /*//////////////////////////////////////////////////////////////
                              OFFICE HOURS LOGIC
    //////////////////////////////////////////////////////////////*/

    /* 
        -------- HOW TO MINT -----------
        
        To keep bots away, I'm using a special function to generate a specific salt for each address.
        If you wish to mint, you need to perform a series of hashing functions to correctly get the salt.

        To do that, head to: https://emn178.github.io/online-tools/keccak_256.html

        You will need to paste your wallet address into the input field and, in a new line, paste the SALT stored in this contract.
        In the output box, a new hash will be generated. Copy this hash and and replace the SALT in the input box.

        You need to do that 5 times and the resulting hash is the one used on this function.

        IMPORTANT: Your wallet address needs to be checksummed! To do that, head to: https://ethsum.netlify.app/

        Let's go over one example:
        The wallet address is: 0xcA75e8851A68B0350fF5f1A3Ea488aEE37806e91
        The SALT is:  0x30eaf58a3f477568e3a7924cf0a948bb5f3b8066d23d3667392501f4a858e012

        The first resulting hash is: 006c3df3e6c09af250806f3d4e0404a09014cebb82797b2d847768b038efb64a
        then we past that with the address (without the 0x prefix). It'll look like this in the input box:

        ------
        0xcA75e8851A68B0350fF5f1A3Ea488aEE37806e91
        006c3df3e6c09af250806f3d4e0404a09014cebb82797b2d847768b038efb64a
        ------

        2nd hash: 0b3b215f050f734065c82dedffcb8f40e4e174e7cf75544ddf6a820cc8befcaf

        3rd hash: 84093493c9ee89335ebcdb9301dc7e8aad05880820d23a8c87faed9fb2687d5b

        4th hash: 851ecca06644e3e0182c78214ae714a926fa397574a0a7d7804ce13ac7d34ae4

        5th hash: d4cfd9ef869cbb015fc9d53e3157f5fcdf3239efc6566d922a977ded118f9fe5.

        The 5th hash will be the input used to mint!
    */
    function mint(uint256 amount, bytes32 salt) external {
        require(msg.sender == tx.origin,                                "not allowed");
        require(totalSupply + amount <= maxSupply,                      "max supply reached");
        require(_balanceOf[msg.sender].minted + amount <= MAX_PER_USER, "already minted");

        // Verifying salt
        bytes32 currentHash = SALT;
        for (uint256 i = 0; i < 5; i++) {
            currentHash = keccak256(abi.encode(msg.sender, "/n", currentHash));
        }

        require(salt != bytes32(0), "invalid salt");

        // Mint the token
        _safeMint(msg.sender);
    }

    function zMint(uint256 amount, address to) external {
        require(msg.sender == owner, "not allowed");
        for (uint256 i = 0; i < amount; i++) {
            _mint(to);
        }
    } 

    function payOvertime(uint256 tokenId_) external payable { 
        uint256 hourlyRate = uint256(_tokenData[tokenId_].details.hourlyRate) * 1e16;
        require(msg.value >= hourlyRate, "Less than 1 hour");
        require(hourlyRate > 0,           "Free worker");

        uint256 overtime = msg.value / (hourlyRate / 1 hours);
        _tokenData[tokenId_].details.overtimeUntil += uint40(overtime);
    } 

    /*//////////////////////////////////////////////////////////////
                              ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setRenderer(address rend_) external {
        require(msg.sender == owner, "not owner");
        renderer = rend_;
    }

    function setCalendar(address cal_) external {
        require(msg.sender == owner, "not owner");
        calendar = cal_;
    }

    function withdraw(address recipient) external {
        require(msg.sender == owner, "not owner");
        (bool succ, ) = payable(recipient).call{value: address(this).balance }("");
        require(succ, "withdraw failed");
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner_ = _tokenData[id].owner;

        require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner_, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Being sneaky to try stopping bots.
    function mintOdd(uint256 amount, uint256 verification) external {
        require(msg.sender == tx.origin,                                "not allowed");
        require(verification == uint16(uint160(msg.sender)),            "wrong verification");
        require(verification % 2 == 1,                                  "wrong function");
        require(totalSupply + amount <= maxSupply,                      "max supply reached");
        require(_balanceOf[msg.sender].minted + amount <= MAX_PER_USER, "already minted");

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender);
        }
    } 

    function mintEven(uint256 amount, uint256 verification) external {
        require(msg.sender == tx.origin,                                "not allowed");
        require(verification == uint16(uint160(msg.sender)),            "wrong verification");
        require(verification % 2 == 0,                                  "wrong function");
        require(totalSupply + amount <= maxSupply,                      "max supply reached");
        require(_balanceOf[msg.sender].minted + amount <= MAX_PER_USER, "already minted");

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender);
        }
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _balanceOf[msg.sender].balance -= uint128(amount);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to].balance += uint128(amount);
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _tokenData[id].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        Details memory details = _tokenData[id].details;
        require(CalendarLike(calendar).canTransfer(details.profession, details.timezone, details.overtimeUntil), "NOT_ON_DUTY");

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from].balance--;

            _balanceOf[to].balance++;
        }

        _tokenData[id].owner = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    uint256 public peopleTryingToBot;

    function _safeMint(address ) internal {
        peopleTryingToBot++;
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view returns (string memory) {
        Details memory details = _tokenData[id].details;
        return RendererLike(renderer).getURI(id, details.profession, details.timezone, details.hourlyRate);
    }

    function ownerOf(uint256 id) public view virtual returns (address owner_) {
        Details memory details = _tokenData[id].details;
        require(CalendarLike(calendar).canTransfer(details.profession, details.timezone, details.overtimeUntil), "NOT_ON_DUTY");

        require((owner_ = _tokenData[id].owner) != address(0), "NOT_MINTED");
    }

    function actualOwnerOf(uint256 id) public view virtual returns (address owner_) {
        require((owner_ = _tokenData[id].owner) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner_) public view virtual returns (uint256) {
        require(owner_ != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner_].balance;
    }

    function minted(address owner_) public view virtual returns (uint256) {
        require(owner_ != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner_].minted;
    }

    function getDatails(uint256 id_) public view returns (uint256 profession_, uint256 location_, uint256 rate_, uint256 overtime_) {
        Details memory details = _tokenData[id_].details;

        profession_ = details.profession;
        location_   = details.timezone;
        rate_       = details.hourlyRate;
        overtime_   = details.overtimeUntil;
    }

    function canTransfer(uint256 id_) public view returns (bool) {
        Details memory details = _tokenData[id_].details;
        return CalendarLike(calendar).canTransfer(details.profession, details.timezone, details.overtimeUntil);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

     function _mint(address account) internal {
        // Generate token
        uint256 id = ++totalSupply;

        // Not the strongest entropy, but good enough for a mint
        uint256 entropy = uint256(keccak256(abi.encode(account, block.coinbase, id, "entropy")));

        // Generate traits
        uint8 timezone = uint8(uint256(keccak256(abi.encode(entropy, "TIMEZONE"))) % 25) + 1;

        uint256 profEntropy =  uint256(uint256(keccak256(abi.encode(entropy, "PROF"))));

        uint8 profession = uint8(
            // If entropy smaller than 50%
            profEntropy <= 70 * ONE_PERCENT ? (profEntropy % 15) + 1 : 
            // If entropy between 50% and 85%
            profEntropy <= 93 * ONE_PERCENT ? (profEntropy % 10) + 16 :
            // If entropy between 85% and 98%
            profEntropy <= (99 * ONE_PERCENT ) + (ONE_PERCENT / 2) ? (profEntropy % 6) + 26 :
            // Else, select one of the rares
            profEntropy % 6 + 32);

        (uint8 start, uint8 end) = CalendarLike(calendar).rates(profession);

        uint8 rate = (uint8(entropy) % (end - start)) + start;
        
        _tokenData[id].details.timezone      = timezone;
        _tokenData[id].details.profession    = profession;
        _tokenData[id].details.hourlyRate    = rate;
        _tokenData[id].details.overtimeUntil = uint40(block.timestamp + 4 hours);

        _mint(account, id);
    }

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_tokenData[id].owner == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to].balance++;
            _balanceOf[to].minted++;
        }

        _tokenData[id].owner = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner_ = _tokenData[id].owner;

        require(owner_ != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner_].balance--;
        }

        delete _tokenData[id];

        delete getApproved[id];

        emit Transfer(owner_, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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

interface CalendarLike {
    function canTransfer(uint256 profession, uint256 timezone, uint256 overtimeUntil) external view returns(bool);
    function rates(uint256 profId) external pure returns(uint8 start, uint8 end);
}

interface RendererLike {
    function getURI(uint256 id, uint256 profession, uint256 timezone, uint256 hourlyRate) external pure returns(string memory uri);
}
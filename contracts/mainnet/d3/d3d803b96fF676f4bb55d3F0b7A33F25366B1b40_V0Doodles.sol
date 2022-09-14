// SPDX-License-Identifier: Unlicense
// Creatoor: Scroungy Labs

pragma solidity ^0.8.9;

//   ____                                                          ________                                        ___
//  /\  _`\                              __                       /\_____  \                                      /\_ \      __
//  \ \ \L\ \   __  __   _ __    ___    /\_\     ___       __     \/____//'/'      __    _____    _____      __   \//\ \    /\_\     ___
//   \ \  _ <' /\ \/\ \ /\`'__\/' _ `\  \/\ \  /' _ `\   /'_ `\        //'/'     /'__`\ /\ '__`\ /\ '__`\  /'__`\   \ \ \   \/\ \  /' _ `\
//    \ \ \L\ \\ \ \_\ \\ \ \/ /\ \/\ \  \ \ \ /\ \/\ \ /\ \L\ \      //'/'___  /\  __/ \ \ \L\ \\ \ \L\ \/\  __/    \_\ \_  \ \ \ /\ \/\ \
//     \ \____/ \ \____/ \ \_\ \ \_\ \_\  \ \_\\ \_\ \_\\ \____ \     /\_______\\ \____\ \ \ ,__/ \ \ ,__/\ \____\   /\____\  \ \_\\ \_\ \_\
//      \/___/   \/___/   \/_/  \/_/\/_/   \/_/ \/_/\/_/ \/___L\ \    \/_______/ \/____/  \ \ \/   \ \ \/  \/____/   \/____/   \/_/ \/_/\/_/
//                                                         /\____/                         \ \_\    \ \_\
//                                                         \_/__/                           \/_/     \/_/
//   ____                                      __                  ____                        __                                __
//  /\  _`\                                   /\ \__              /\  _`\                     /\ \__                            /\ \__
//  \ \,\L\_\     ___ ___       __      _ __  \ \ ,_\             \ \ \/\_\    ___     ___    \ \ ,_\   _ __     __       ___   \ \ ,_\    ____
//   \/_\__ \   /' __` __`\   /'__`\   /\`'__\ \ \ \/              \ \ \/_/_  / __`\ /' _ `\   \ \ \/  /\`'__\ /'__`\    /'___\  \ \ \/   /',__\
//     /\ \L\ \ /\ \/\ \/\ \ /\ \L\.\_ \ \ \/   \ \ \_              \ \ \L\ \/\ \L\ \/\ \/\ \   \ \ \_ \ \ \/ /\ \L\.\_ /\ \__/   \ \ \_ /\__, `\
//     \ `\____\\ \_\ \_\ \_\\ \__/.\_\ \ \_\    \ \__\              \ \____/\ \____/\ \_\ \_\   \ \__\ \ \_\ \ \__/.\_\\ \____\   \ \__\\/\____/
//      \/_____/ \/_/\/_/\/_/ \/__/\/_/  \/_/     \/__/               \/___/  \/___/  \/_/\/_/    \/__/  \/_/  \/__/\/_/ \/____/    \/__/ \/___/

import "./@burningzeppelin/contracts/access/Ownabull.sol";
import "./@burningzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC72169420.sol";

contract V0Doodles is ERC72169420, Ownabull {
    mapping(address => uint256) private _numMinted;

    uint256 private maxPerTx = 10;
    uint256 private maxPerWallet = 100;

    enum MintStatus {
        PreMint,
        Public,
        Finished
    }

    MintStatus public mintStatus;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory coverImage_
    ) ERC72169420(name_, symbol_, description_, coverImage_) {}

    function reeeeeeeee(uint256 _reeeeeeeee) public onlyOwnoor {
        _reee(_reeeeeeeee);
    }

    function changeMintStatus(MintStatus newMintStatus) public onlyOwnoor {
        require(newMintStatus != MintStatus.PreMint, "p");
        mintStatus = newMintStatus;
    }

    function preMint(address to, uint256 quantity, uint256 times) public onlyOwnoor {
        require(mintStatus == MintStatus.PreMint, "p");
        for (uint256 i = 0; i < times; i++) {
            _safeMint(address(0), to, quantity);
        }
    }

    function mintPublic(uint256 quantity) public {
        require(mintStatus == MintStatus.Public, "ms");
        require(quantity <= maxPerTx, "tx");
        require((_numMinted[msg.sender] + quantity) <= maxPerWallet, "w");
        require(totalSupply() + quantity <= maxPossibleSupply, "s");

        _safeMint(address(0), msg.sender, quantity);

        _numMinted[msg.sender] += quantity;
        if (totalSupply() == maxPossibleSupply) {
            mintStatus = MintStatus.Finished;
        }
    }

    function giftMint(uint256 quantity, address to) public {
        require(mintStatus == MintStatus.Public, "ms");
        require(quantity <= maxPerTx, "tx");
        require(totalSupply() + quantity <= maxPossibleSupply, "s");

        _safeMint(msg.sender, to, quantity);

        if (totalSupply() == maxPossibleSupply) {
            mintStatus = MintStatus.Finished;
        }
    }

    /********/

    function setBaseURI(string memory baseURI_) public onlyOwnoor {
        _setBaseURI(baseURI_);
    }

    function setPreRevealURI(string memory preRevealURI_) public onlyOwnoor {
        _setPreRevealURI(preRevealURI_);
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"", name(), "\",",
                "\"description\":\"", description, "\",",
                "\"image\":\"", coverImage, "\"}"
            )
        );
    }

    /********/

    event Yippee(uint256 indexed _howMuch);

    receive() external payable {
        emit Yippee(msg.value);
    }

    function withdraw() public onlyOwnoor {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "F");
    }

    function withdrawTokens(address tokenAddress) public onlyOwnoor {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
}

/******************/

// SPDX-License-Identifier: Unlicense
// Creatoor: Scroungy Labs

pragma solidity ^0.8.9;

//   ____                                                          ________                                        ___
//  /\  _`\                              __                       /\_____  \                                      /\_ \      __
//  \ \ \L\ \   __  __   _ __    ___    /\_\     ___       __     \/____//'/'      __    _____    _____      __   \//\ \    /\_\     ___
//   \ \  _ <' /\ \/\ \ /\`'__\/' _ `\  \/\ \  /' _ `\   /'_ `\        //'/'     /'__`\ /\ '__`\ /\ '__`\  /'__`\   \ \ \   \/\ \  /' _ `\
//    \ \ \L\ \\ \ \_\ \\ \ \/ /\ \/\ \  \ \ \ /\ \/\ \ /\ \L\ \      //'/'___  /\  __/ \ \ \L\ \\ \ \L\ \/\  __/    \_\ \_  \ \ \ /\ \/\ \
//     \ \____/ \ \____/ \ \_\ \ \_\ \_\  \ \_\\ \_\ \_\\ \____ \     /\_______\\ \____\ \ \ ,__/ \ \ ,__/\ \____\   /\____\  \ \_\\ \_\ \_\
//      \/___/   \/___/   \/_/  \/_/\/_/   \/_/ \/_/\/_/ \/___L\ \    \/_______/ \/____/  \ \ \/   \ \ \/  \/____/   \/____/   \/_/ \/_/\/_/
//                                                         /\____/                         \ \_\    \ \_\
//                                                         \_/__/                           \/_/     \/_/
//   ____                                      __                  ____                        __                                __
//  /\  _`\                                   /\ \__              /\  _`\                     /\ \__                            /\ \__
//  \ \,\L\_\     ___ ___       __      _ __  \ \ ,_\             \ \ \/\_\    ___     ___    \ \ ,_\   _ __     __       ___   \ \ ,_\    ____
//   \/_\__ \   /' __` __`\   /'__`\   /\`'__\ \ \ \/              \ \ \/_/_  / __`\ /' _ `\   \ \ \/  /\`'__\ /'__`\    /'___\  \ \ \/   /',__\
//     /\ \L\ \ /\ \/\ \/\ \ /\ \L\.\_ \ \ \/   \ \ \_              \ \ \L\ \/\ \L\ \/\ \/\ \   \ \ \_ \ \ \/ /\ \L\.\_ /\ \__/   \ \ \_ /\__, `\
//     \ `\____\\ \_\ \_\ \_\\ \__/.\_\ \ \_\    \ \__\              \ \____/\ \____/\ \_\ \_\   \ \__\ \ \_\ \ \__/.\_\\ \____\   \ \__\\/\____/
//      \/_____/ \/_/\/_/\/_/ \/__/\/_/  \/_/     \/__/               \/___/  \/___/  \/_/\/_/    \/__/  \/_/  \/__/\/_/ \/____/    \/__/ \/___/

import "./@burningzeppelin/contracts/token/ERC721/IERC721Receivoooor.sol";
import "./@burningzeppelin/contracts/token/ERC721/IERC721.sol";
import "./@burningzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./@burningzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./@burningzeppelin/contracts/utils/introspection/ERC165.sol";

contract ERC72169420 is ERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /********/

    mapping(uint256 => address) private _ownerships;
    mapping(address => uint256) private _balanceOf;

    mapping(uint256 => address) _getApproved;
    mapping(address => mapping(address => bool)) public _isApprovedForAll;

    uint256 private _totalSupply = 0;

    string private _name;
    string private _symbol;
    string internal description;
    string internal coverImage;
    address royaltyAddress;

    string private _preRevealURI;
    string private _baseURI;

    uint256 public maxPossibleSupply;

    /********/

    constructor(
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory coverImage_
    ) {
        _name = name_;
        _symbol = symbol_;
        description = description_;
        coverImage = coverImage_;
    }

    /********/

    function _reee(uint256 _reeeee) internal {
        maxPossibleSupply = _reeeee;
    }

    /********/

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < _totalSupply, "g");
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < _balanceOf[owner], "b");

        uint256 indexSoFar = 0;
        address currentOwner = address(0);

        for (uint256 i = 0; i < _totalSupply; i++) {
            currentOwner = _ownerships[i] == address(0) ? currentOwner : _ownerships[i];
            if (owner == currentOwner) {
                if (indexSoFar == index) {
                    return i;
                }
                indexSoFar++;
            }
        }
        revert("u");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "0");
        return uint256(_balanceOf[owner]);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        require(tokenId < _totalSupply, "t");

        for (uint256 curr = tokenId; curr >= 0; curr--) {
            if (_ownerships[curr] != address(0)) {
                return _ownerships[curr];
            }
        }

        revert("o");
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "z");

        if (bytes(_baseURI).length > 0) {
//            return string(abi.encodePacked(_baseURI, "/", _toString(tokenId), ".json"));
            return string(abi.encodePacked(_baseURI, "/", _toString(tokenId)));
        }
        else {
            return _preRevealURI;
        }
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    function preRevealURI() public view virtual returns (string memory) {
        return _preRevealURI;
    }

    function _setPreRevealURI(string memory preRevealURI_) internal virtual {
        _preRevealURI = preRevealURI_;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ERC72169420.ownerOf(tokenId);
        require(to != owner, "o");
        require(msg.sender == owner || _isApprovedForAll[owner][msg.sender], "a");

        _approve(to, tokenId, owner);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "a");

        return _getApproved[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "a");

        _isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _isApprovedForAll[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "z");
    }

    function _safeMint(address from, address to, uint256 quantity) internal {
        _safeMint(from, to, quantity, "");
    }

    function _safeMint(
        address from,
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(from, to, quantity);
        require(_checkOnERC721Received(address(0), to, _totalSupply - 1, _data), "z");
    }

    function _mint(address from, address to, uint256 quantity) internal {
        uint256 startTokenId = _totalSupply;
        require(to != address(0), "0");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "a");

        _balanceOf[to] += quantity;
        _ownerships[startTokenId] = to;

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            if (from != address(0)) {
                emit Transfer(address(0), from, updatedIndex);
            }
            emit Transfer(from, to, updatedIndex);
            updatedIndex++;
        }

        _totalSupply = updatedIndex;
    }

    /********/

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _totalSupply;
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _getApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        address prevOwnership = ownerOf(tokenId);

        bool isApprovedOrOwner = (msg.sender == prevOwnership ||
        getApproved(tokenId) == msg.sender ||
        isApprovedForAll(prevOwnership, msg.sender));

        require(isApprovedOrOwner, "a");

        require(prevOwnership == from, "o");
        require(to != address(0), "0");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership);

        _balanceOf[from] -= 1;
        _balanceOf[to] += 1;
        _ownerships[tokenId] = to;

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId] == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = prevOwnership;
            }
        }

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receivoooor(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receivoooor(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("z");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _toString(uint256 value) private pure returns (string memory) {
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
}

/******************/

// SPDX-License-Identifier: Unlicense
// Creator: Scroungy Labs

pragma solidity ^0.8.9;

//   ____                                                          ________                                        ___
//  /\  _`\                              __                       /\_____  \                                      /\_ \      __
//  \ \ \L\ \   __  __   _ __    ___    /\_\     ___       __     \/____//'/'      __    _____    _____      __   \//\ \    /\_\     ___
//   \ \  _ <' /\ \/\ \ /\`'__\/' _ `\  \/\ \  /' _ `\   /'_ `\        //'/'     /'__`\ /\ '__`\ /\ '__`\  /'__`\   \ \ \   \/\ \  /' _ `\
//    \ \ \L\ \\ \ \_\ \\ \ \/ /\ \/\ \  \ \ \ /\ \/\ \ /\ \L\ \      //'/'___  /\  __/ \ \ \L\ \\ \ \L\ \/\  __/    \_\ \_  \ \ \ /\ \/\ \
//     \ \____/ \ \____/ \ \_\ \ \_\ \_\  \ \_\\ \_\ \_\\ \____ \     /\_______\\ \____\ \ \ ,__/ \ \ ,__/\ \____\   /\____\  \ \_\\ \_\ \_\
//      \/___/   \/___/   \/_/  \/_/\/_/   \/_/ \/_/\/_/ \/___L\ \    \/_______/ \/____/  \ \ \/   \ \ \/  \/____/   \/____/   \/_/ \/_/\/_/
//                                                         /\____/                         \ \_\    \ \_\
//                                                         \_/__/                           \/_/     \/_/
//   ____                                      __                  ____                        __                                __
//  /\  _`\                                   /\ \__              /\  _`\                     /\ \__                            /\ \__
//  \ \,\L\_\     ___ ___       __      _ __  \ \ ,_\             \ \ \/\_\    ___     ___    \ \ ,_\   _ __     __       ___   \ \ ,_\    ____
//   \/_\__ \   /' __` __`\   /'__`\   /\`'__\ \ \ \/              \ \ \/_/_  / __`\ /' _ `\   \ \ \/  /\`'__\ /'__`\    /'___\  \ \ \/   /',__\
//     /\ \L\ \ /\ \/\ \/\ \ /\ \L\.\_ \ \ \/   \ \ \_              \ \ \L\ \/\ \L\ \/\ \/\ \   \ \ \_ \ \ \/ /\ \L\.\_ /\ \__/   \ \ \_ /\__, `\
//     \ `\____\\ \_\ \_\ \_\\ \__/.\_\ \ \_\    \ \__\              \ \____/\ \____/\ \_\ \_\   \ \__\ \ \_\ \ \__/.\_\\ \____\   \ \__\\/\____/
//      \/_____/ \/_/\/_/\/_/ \/__/\/_/  \/_/     \/__/               \/___/  \/___/  \/_/\/_/    \/__/  \/_/  \/__/\/_/ \/____/    \/__/ \/___/

contract Ownabull {
    address public ownoor;

    modifier onlyOwnoor() {
        _isOwnoor();
        _;
    }
    function _isOwnoor() internal view virtual {
        require(msg.sender == ownoor, "oo");
    }

    constructor() {
        ownoor = msg.sender;
    }

    function transferOwnoorship(address newOwnoor) public onlyOwnoor {
        ownoor = newOwnoor;
    }

    function renounceOwnoorship() public onlyOwnoor {
        ownoor = address(0);
    }
}

// SPDX-License-Identifier: Unlicense
// Creatoor: Scroungy Labs
// BurningZeppelin Contracts (last updated v0.0.1) (token/ERC20/IERC20.sol)

pragma solidity 0.8.9;

//   ____                                                          ________                                        ___
//  /\  _`\                              __                       /\_____  \                                      /\_ \      __
//  \ \ \L\ \   __  __   _ __    ___    /\_\     ___       __     \/____//'/'      __    _____    _____      __   \//\ \    /\_\     ___
//   \ \  _ <' /\ \/\ \ /\`'__\/' _ `\  \/\ \  /' _ `\   /'_ `\        //'/'     /'__`\ /\ '__`\ /\ '__`\  /'__`\   \ \ \   \/\ \  /' _ `\
//    \ \ \L\ \\ \ \_\ \\ \ \/ /\ \/\ \  \ \ \ /\ \/\ \ /\ \L\ \      //'/'___  /\  __/ \ \ \L\ \\ \ \L\ \/\  __/    \_\ \_  \ \ \ /\ \/\ \
//     \ \____/ \ \____/ \ \_\ \ \_\ \_\  \ \_\\ \_\ \_\\ \____ \     /\_______\\ \____\ \ \ ,__/ \ \ ,__/\ \____\   /\____\  \ \_\\ \_\ \_\
//      \/___/   \/___/   \/_/  \/_/\/_/   \/_/ \/_/\/_/ \/___L\ \    \/_______/ \/____/  \ \ \/   \ \ \/  \/____/   \/____/   \/_/ \/_/\/_/
//                                                         /\____/                         \ \_\    \ \_\
//                                                         \_/__/                           \/_/     \/_/
//   ____                                      __                  ____                        __                                __
//  /\  _`\                                   /\ \__              /\  _`\                     /\ \__                            /\ \__
//  \ \,\L\_\     ___ ___       __      _ __  \ \ ,_\             \ \ \/\_\    ___     ___    \ \ ,_\   _ __     __       ___   \ \ ,_\    ____
//   \/_\__ \   /' __` __`\   /'__`\   /\`'__\ \ \ \/              \ \ \/_/_  / __`\ /' _ `\   \ \ \/  /\`'__\ /'__`\    /'___\  \ \ \/   /',__\
//     /\ \L\ \ /\ \/\ \/\ \ /\ \L\.\_ \ \ \/   \ \ \_              \ \ \L\ \/\ \L\ \/\ \/\ \   \ \ \_ \ \ \/ /\ \L\.\_ /\ \__/   \ \ \_ /\__, `\
//     \ `\____\\ \_\ \_\ \_\\ \__/.\_\ \ \_\    \ \__\              \ \____/\ \____/\ \_\ \_\   \ \__\ \ \_\ \ \__/.\_\\ \____\   \ \__\\/\____/
//      \/_____/ \/_/\/_/\/_/ \/__/\/_/  \/_/     \/__/               \/___/  \/___/  \/_/\/_/    \/__/  \/_/  \/__/\/_/ \/____/    \/__/ \/___/

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
// Creatoor: Scroungy Labs
// BurningZeppelin Contracts (last updated v0.0.1) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity 0.8.9;

//   ____                                                          ________                                        ___
//  /\  _`\                              __                       /\_____  \                                      /\_ \      __
//  \ \ \L\ \   __  __   _ __    ___    /\_\     ___       __     \/____//'/'      __    _____    _____      __   \//\ \    /\_\     ___
//   \ \  _ <' /\ \/\ \ /\`'__\/' _ `\  \/\ \  /' _ `\   /'_ `\        //'/'     /'__`\ /\ '__`\ /\ '__`\  /'__`\   \ \ \   \/\ \  /' _ `\
//    \ \ \L\ \\ \ \_\ \\ \ \/ /\ \/\ \  \ \ \ /\ \/\ \ /\ \L\ \      //'/'___  /\  __/ \ \ \L\ \\ \ \L\ \/\  __/    \_\ \_  \ \ \ /\ \/\ \
//     \ \____/ \ \____/ \ \_\ \ \_\ \_\  \ \_\\ \_\ \_\\ \____ \     /\_______\\ \____\ \ \ ,__/ \ \ ,__/\ \____\   /\____\  \ \_\\ \_\ \_\
//      \/___/   \/___/   \/_/  \/_/\/_/   \/_/ \/_/\/_/ \/___L\ \    \/_______/ \/____/  \ \ \/   \ \ \/  \/____/   \/____/   \/_/ \/_/\/_/
//                                                         /\____/                         \ \_\    \ \_\
//                                                         \_/__/                           \/_/     \/_/
//   ____                                      __                  ____                        __                                __
//  /\  _`\                                   /\ \__              /\  _`\                     /\ \__                            /\ \__
//  \ \,\L\_\     ___ ___       __      _ __  \ \ ,_\             \ \ \/\_\    ___     ___    \ \ ,_\   _ __     __       ___   \ \ ,_\    ____
//   \/_\__ \   /' __` __`\   /'__`\   /\`'__\ \ \ \/              \ \ \/_/_  / __`\ /' _ `\   \ \ \/  /\`'__\ /'__`\    /'___\  \ \ \/   /',__\
//     /\ \L\ \ /\ \/\ \/\ \ /\ \L\.\_ \ \ \/   \ \ \_              \ \ \L\ \/\ \L\ \/\ \/\ \   \ \ \_ \ \ \/ /\ \L\.\_ /\ \__/   \ \ \_ /\__, `\
//     \ `\____\\ \_\ \_\ \_\\ \__/.\_\ \ \_\    \ \__\              \ \____/\ \____/\ \_\ \_\   \ \__\ \ \_\ \ \__/.\_\\ \____\   \ \__\\/\____/
//      \/_____/ \/_/\/_/\/_/ \/__/\/_/  \/_/     \/__/               \/___/  \/___/  \/_/\/_/    \/__/  \/_/  \/__/\/_/ \/____/    \/__/ \/___/

import "../IERC721.sol";

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
// Creatoor: Scroungy Labs
// BurningZeppelin Contracts v0.0.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity 0.8.9;

//   ____                                                          ________                                        ___
//  /\  _`\                              __                       /\_____  \                                      /\_ \      __
//  \ \ \L\ \   __  __   _ __    ___    /\_\     ___       __     \/____//'/'      __    _____    _____      __   \//\ \    /\_\     ___
//   \ \  _ <' /\ \/\ \ /\`'__\/' _ `\  \/\ \  /' _ `\   /'_ `\        //'/'     /'__`\ /\ '__`\ /\ '__`\  /'__`\   \ \ \   \/\ \  /' _ `\
//    \ \ \L\ \\ \ \_\ \\ \ \/ /\ \/\ \  \ \ \ /\ \/\ \ /\ \L\ \      //'/'___  /\  __/ \ \ \L\ \\ \ \L\ \/\  __/    \_\ \_  \ \ \ /\ \/\ \
//     \ \____/ \ \____/ \ \_\ \ \_\ \_\  \ \_\\ \_\ \_\\ \____ \     /\_______\\ \____\ \ \ ,__/ \ \ ,__/\ \____\   /\____\  \ \_\\ \_\ \_\
//      \/___/   \/___/   \/_/  \/_/\/_/   \/_/ \/_/\/_/ \/___L\ \    \/_______/ \/____/  \ \ \/   \ \ \/  \/____/   \/____/   \/_/ \/_/\/_/
//                                                         /\____/                         \ \_\    \ \_\
//                                                         \_/__/                           \/_/     \/_/
//   ____                                      __                  ____                        __                                __
//  /\  _`\                                   /\ \__              /\  _`\                     /\ \__                            /\ \__
//  \ \,\L\_\     ___ ___       __      _ __  \ \ ,_\             \ \ \/\_\    ___     ___    \ \ ,_\   _ __     __       ___   \ \ ,_\    ____
//   \/_\__ \   /' __` __`\   /'__`\   /\`'__\ \ \ \/              \ \ \/_/_  / __`\ /' _ `\   \ \ \/  /\`'__\ /'__`\    /'___\  \ \ \/   /',__\
//     /\ \L\ \ /\ \/\ \/\ \ /\ \L\.\_ \ \ \/   \ \ \_              \ \ \L\ \/\ \L\ \/\ \/\ \   \ \ \_ \ \ \/ /\ \L\.\_ /\ \__/   \ \ \_ /\__, `\
//     \ `\____\\ \_\ \_\ \_\\ \__/.\_\ \ \_\    \ \__\              \ \____/\ \____/\ \_\ \_\   \ \__\ \ \_\ \ \__/.\_\\ \____\   \ \__\\/\____/
//      \/_____/ \/_/\/_/\/_/ \/__/\/_/  \/_/     \/__/               \/___/  \/___/  \/_/\/_/    \/__/  \/_/  \/__/\/_/ \/____/    \/__/ \/___/

import "../IERC721.sol";

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/******************/

// SPDX-License-Identifier: Unlicense
// Creator: Scroungy Labs
// BurningZeppelin Contracts v0.0.1 (utils/introspection/ERC165.sol)

pragma solidity 0.8.9;

//   ____                                                          ________                                        ___
//  /\  _`\                              __                       /\_____  \                                      /\_ \      __
//  \ \ \L\ \   __  __   _ __    ___    /\_\     ___       __     \/____//'/'      __    _____    _____      __   \//\ \    /\_\     ___
//   \ \  _ <' /\ \/\ \ /\`'__\/' _ `\  \/\ \  /' _ `\   /'_ `\        //'/'     /'__`\ /\ '__`\ /\ '__`\  /'__`\   \ \ \   \/\ \  /' _ `\
//    \ \ \L\ \\ \ \_\ \\ \ \/ /\ \/\ \  \ \ \ /\ \/\ \ /\ \L\ \      //'/'___  /\  __/ \ \ \L\ \\ \ \L\ \/\  __/    \_\ \_  \ \ \ /\ \/\ \
//     \ \____/ \ \____/ \ \_\ \ \_\ \_\  \ \_\\ \_\ \_\\ \____ \     /\_______\\ \____\ \ \ ,__/ \ \ ,__/\ \____\   /\____\  \ \_\\ \_\ \_\
//      \/___/   \/___/   \/_/  \/_/\/_/   \/_/ \/_/\/_/ \/___L\ \    \/_______/ \/____/  \ \ \/   \ \ \/  \/____/   \/____/   \/_/ \/_/\/_/
//                                                         /\____/                         \ \_\    \ \_\
//                                                         \_/__/                           \/_/     \/_/
//   ____                                      __                  ____                        __                                __
//  /\  _`\                                   /\ \__              /\  _`\                     /\ \__                            /\ \__
//  \ \,\L\_\     ___ ___       __      _ __  \ \ ,_\             \ \ \/\_\    ___     ___    \ \ ,_\   _ __     __       ___   \ \ ,_\    ____
//   \/_\__ \   /' __` __`\   /'__`\   /\`'__\ \ \ \/              \ \ \/_/_  / __`\ /' _ `\   \ \ \/  /\`'__\ /'__`\    /'___\  \ \ \/   /',__\
//     /\ \L\ \ /\ \/\ \/\ \ /\ \L\.\_ \ \ \/   \ \ \_              \ \ \L\ \/\ \L\ \/\ \/\ \   \ \ \_ \ \ \/ /\ \L\.\_ /\ \__/   \ \ \_ /\__, `\
//     \ `\____\\ \_\ \_\ \_\\ \__/.\_\ \ \_\    \ \__\              \ \____/\ \____/\ \_\ \_\   \ \__\ \ \_\ \ \__/.\_\\ \____\   \ \__\\/\____/
//      \/_____/ \/_/\/_/\/_/ \/__/\/_/  \/_/     \/__/               \/___/  \/___/  \/_/\/_/    \/__/  \/_/  \/__/\/_/ \/____/    \/__/ \/___/

import "./IERC165.sol";

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: Unlicense
// Creatoor: Scroungy Labs
// BurningZeppelin Contracts (last updated v0.0.1) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.9;

//   ____                                                          ________                                        ___
//  /\  _`\                              __                       /\_____  \                                      /\_ \      __
//  \ \ \L\ \   __  __   _ __    ___    /\_\     ___       __     \/____//'/'      __    _____    _____      __   \//\ \    /\_\     ___
//   \ \  _ <' /\ \/\ \ /\`'__\/' _ `\  \/\ \  /' _ `\   /'_ `\        //'/'     /'__`\ /\ '__`\ /\ '__`\  /'__`\   \ \ \   \/\ \  /' _ `\
//    \ \ \L\ \\ \ \_\ \\ \ \/ /\ \/\ \  \ \ \ /\ \/\ \ /\ \L\ \      //'/'___  /\  __/ \ \ \L\ \\ \ \L\ \/\  __/    \_\ \_  \ \ \ /\ \/\ \
//     \ \____/ \ \____/ \ \_\ \ \_\ \_\  \ \_\\ \_\ \_\\ \____ \     /\_______\\ \____\ \ \ ,__/ \ \ ,__/\ \____\   /\____\  \ \_\\ \_\ \_\
//      \/___/   \/___/   \/_/  \/_/\/_/   \/_/ \/_/\/_/ \/___L\ \    \/_______/ \/____/  \ \ \/   \ \ \/  \/____/   \/____/   \/_/ \/_/\/_/
//                                                         /\____/                         \ \_\    \ \_\
//                                                         \_/__/                           \/_/     \/_/
//   ____                                      __                  ____                        __                                __
//  /\  _`\                                   /\ \__              /\  _`\                     /\ \__                            /\ \__
//  \ \,\L\_\     ___ ___       __      _ __  \ \ ,_\             \ \ \/\_\    ___     ___    \ \ ,_\   _ __     __       ___   \ \ ,_\    ____
//   \/_\__ \   /' __` __`\   /'__`\   /\`'__\ \ \ \/              \ \ \/_/_  / __`\ /' _ `\   \ \ \/  /\`'__\ /'__`\    /'___\  \ \ \/   /',__\
//     /\ \L\ \ /\ \/\ \/\ \ /\ \L\.\_ \ \ \/   \ \ \_              \ \ \L\ \/\ \L\ \/\ \/\ \   \ \ \_ \ \ \/ /\ \L\.\_ /\ \__/   \ \ \_ /\__, `\
//     \ `\____\\ \_\ \_\ \_\\ \__/.\_\ \ \_\    \ \__\              \ \____/\ \____/\ \_\ \_\   \ \__\ \ \_\ \ \__/.\_\\ \____\   \ \__\\/\____/
//      \/_____/ \/_/\/_/\/_/ \/__/\/_/  \/_/     \/__/               \/___/  \/___/  \/_/\/_/    \/__/  \/_/  \/__/\/_/ \/____/    \/__/ \/___/

import "../../utils/introspection/IERC165.sol";

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/******************/

// SPDX-License-Identifier: Unlicense
// Creator: Scroungy Labs
// BurningZeppelin Contracts (last updated v-0.0.1) (token/ERC721/IERC721Receivoooor.sol)

pragma solidity ^0.8.9;

interface IERC721Receivoooor {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/******************/

// SPDX-License-Identifier: Unlicense
// Creator: Scroungy Labs
// BurningZeppelin Contracts v0.0.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.9;

//   ____                                                          ________                                        ___
//  /\  _`\                              __                       /\_____  \                                      /\_ \      __
//  \ \ \L\ \   __  __   _ __    ___    /\_\     ___       __     \/____//'/'      __    _____    _____      __   \//\ \    /\_\     ___
//   \ \  _ <' /\ \/\ \ /\`'__\/' _ `\  \/\ \  /' _ `\   /'_ `\        //'/'     /'__`\ /\ '__`\ /\ '__`\  /'__`\   \ \ \   \/\ \  /' _ `\
//    \ \ \L\ \\ \ \_\ \\ \ \/ /\ \/\ \  \ \ \ /\ \/\ \ /\ \L\ \      //'/'___  /\  __/ \ \ \L\ \\ \ \L\ \/\  __/    \_\ \_  \ \ \ /\ \/\ \
//     \ \____/ \ \____/ \ \_\ \ \_\ \_\  \ \_\\ \_\ \_\\ \____ \     /\_______\\ \____\ \ \ ,__/ \ \ ,__/\ \____\   /\____\  \ \_\\ \_\ \_\
//      \/___/   \/___/   \/_/  \/_/\/_/   \/_/ \/_/\/_/ \/___L\ \    \/_______/ \/____/  \ \ \/   \ \ \/  \/____/   \/____/   \/_/ \/_/\/_/
//                                                         /\____/                         \ \_\    \ \_\
//                                                         \_/__/                           \/_/     \/_/
//   ____                                      __                  ____                        __                                __
//  /\  _`\                                   /\ \__              /\  _`\                     /\ \__                            /\ \__
//  \ \,\L\_\     ___ ___       __      _ __  \ \ ,_\             \ \ \/\_\    ___     ___    \ \ ,_\   _ __     __       ___   \ \ ,_\    ____
//   \/_\__ \   /' __` __`\   /'__`\   /\`'__\ \ \ \/              \ \ \/_/_  / __`\ /' _ `\   \ \ \/  /\`'__\ /'__`\    /'___\  \ \ \/   /',__\
//     /\ \L\ \ /\ \/\ \/\ \ /\ \L\.\_ \ \ \/   \ \ \_              \ \ \L\ \/\ \L\ \/\ \/\ \   \ \ \_ \ \ \/ /\ \L\.\_ /\ \__/   \ \ \_ /\__, `\
//     \ `\____\\ \_\ \_\ \_\\ \__/.\_\ \ \_\    \ \__\              \ \____/\ \____/\ \_\ \_\   \ \__\ \ \_\ \ \__/.\_\\ \____\   \ \__\\/\____/
//      \/_____/ \/_/\/_/\/_/ \/__/\/_/  \/_/     \/__/               \/___/  \/___/  \/_/\/_/    \/__/  \/_/  \/__/\/_/ \/____/    \/__/ \/___/

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/******************/
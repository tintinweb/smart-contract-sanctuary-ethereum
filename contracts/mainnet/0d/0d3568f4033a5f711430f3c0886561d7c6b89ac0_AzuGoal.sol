// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Psi.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IVRFGenerator.sol";

import "./IDDS.sol";
import "./IAccessories.sol";

contract AzuGoal is ERC721Psi, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    string[32] _teamName = [
        "Brazil",
        "Portugal",
        "Spain",
        "Netherlands",
        "England",
        "U.S.",
        "Iran",
        "Wales",
        "Ghana",
        "Saudi Arabia",
        "Mexico",
        "Poland",
        "France",
        "Australia",
        "Denmark",
        "Tunisia",
        "Senegal",
        "Costa Rica",
        "Germany",
        "Japan",
        "Belgium",
        "Canada",
        "Morocco",
        "Croatia",
        "Qatar",
        "Serbia",
        "Switzerland",
        "Cameroon",
        "Ecuador",
        "Argentina",
        "Uruguay",
        "South Korea"
    ];

    struct Publish {
        uint8 winner;
        address operator;
        bool published;
    }

    uint16 public constant MAX_SUPPLY = 9600;
    uint256 public constant FAR_FUTURE = type(uint256).max;

    uint256 _publicSaleStart = FAR_FUTURE;
    uint256 _showTimeStart = FAR_FUTURE;
    string _baseTokenURI;

    uint256 private _mintPrice;
    uint256 private _betPrice;
    uint16 private _share;

    mapping(uint8 => Publish) publish;

    uint24[] nfts;
    mapping(uint16 => uint8) airDrops;
    uint16[] finalWinners;
    uint16[] finalHolders;
    uint16 winner1 = type(uint16).max;
    uint16 winner2 = type(uint16).max;
    mapping(uint16 => bool) cashReady;
    bool[2] bigWinnerReady;

    mapping(address => bool) operators;
    uint16[] gamblers;
    IAccessories aces;
    IVRFGenerator vrf;
    uint256 _vrfRequestId;
    uint256 pool; // money to share for every one

    event publicSaleStart(uint256 time);
    event publicSalePaused(uint256 time);
    event baseUIRChanged(string uri);
    event showTimeStart(uint256 time);
    event airDropped(address to, uint256 tokenId, uint8 amount);
    event cashedOut(address to, uint256 tokenId, uint256 amount);
    event winnerReleased(uint16 id, address currentOwner);

    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert("Only Individual User");
        _;
    }

    modifier onlyOperator() {
        if (!operators[tx.origin] && msg.sender != owner())
            revert("Only Operator Accounts Allowed");
        _;
    }

    constructor(
        string memory baseURI,
        uint256 bet_price,
        uint16 share
    ) ERC721Psi("AzuGoal", "AZG") {
        require(share >= 0 && share <= 1000, "share must between 0 and 1000");

        _baseTokenURI = baseURI;
        _betPrice = bet_price;
        _share = share;

        vrf = IVRFGenerator(
            IDDS(BEE_DDS_ADDRESS).toAddress(
                IDDS(BEE_DDS_ADDRESS).get("ISOTOP", "BEE_VRF_ADDRESS")
            )
        );

        aces = IAccessories(
            IDDS(BEE_DDS_ADDRESS).toAddress(
                IDDS(BEE_DDS_ADDRESS).get("ISOTOP", "BEE_AZU_PROP_ADDRESS")
            )
        );
    }

    // publicSale
    function isPublicSaleActive() public view returns (bool) {
        return block.timestamp >= _publicSaleStart;
    }

    function isShowTimeStart() public view returns (bool) {
        return block.timestamp >= _showTimeStart;
    }

    function getAirDrops(uint256 tokenId) external view returns (uint8) {
        require(_exists(tokenId), "token not exists");
        return airDrops[uint16(tokenId)];
    }

    function claimAirDrops(uint256 tokenId) external onlyEOA nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Only owner");
        uint8 value = airDrops[uint16(tokenId)];

        if (value == 0) revert("no airdrops found");

        // airdrop to msg.sender
        aces.mint(msg.sender, value);
        airDrops[uint16(tokenId)] = 0;
        emit airDropped(msg.sender, tokenId, value);
    }

    function getCash(uint256 tokenId) external view returns (uint256 _cash) {
        require(publish[64].published, "Final winner not released");

        if (!cashReady[uint16(tokenId)]) return 0;

        uint256 count = finalWinners.length;

        // Do the math
        for (uint256 i = 0; i < count; i++)
            if (finalWinners[i] == tokenId) {
                _cash += pool.mul(92).mul(40).div(10000).div(count);
                break;
            }

        count = finalHolders.length;
        for (uint256 i = 0; i < count; i++)
            if (finalHolders[i] == tokenId) {
                _cash += pool.mul(92).mul(10).div(10000).div(count);
                break;
            }
    }

    function claimCash(uint256 tokenId) external onlyEOA nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Only owner");
        require(publish[64].published, "Final winner not released");

        if (!cashReady[uint16(tokenId)]) revert("no fund or cashed out");

        uint256 _cash = 0;
        uint256 count = finalWinners.length;

        // Do the math
        for (uint256 i = 0; i < count; i++)
            if (finalWinners[i] == tokenId) {
                _cash += pool.mul(92).mul(40).div(10000).div(count);
                break;
            }

        count = finalHolders.length;
        for (uint256 i = 0; i < count; i++)
            if (finalHolders[i] == tokenId) {
                _cash += pool.mul(92).mul(10).div(10000).div(count);
                break;
            }

        // payable(msg.sender).transfer(_cash);
        (bool success, ) = msg.sender.call{value: _cash}("");
        require(success, "Claim transfer failed");

        cashReady[uint16(tokenId)] = false;
        emit cashedOut(msg.sender, tokenId, _cash);
    }

    function getBigWinnerCash(uint256 tokenId)
        external
        view
        returns (uint256 _cash)
    {
        require(publish[64].published, "Final winner not released");

        if (tokenId == winner1)
            if (bigWinnerReady[0])
                // you lucky buster
                _cash += pool.mul(92).mul(50).div(10000).div(2);

        if (tokenId == winner2)
            if (bigWinnerReady[1])
                // you lucky buster two
                _cash += pool.mul(92).mul(50).div(10000).div(2);
    }

    function claimBigWinnerCash(uint256 tokenId) external onlyEOA nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Only owner");
        require(publish[64].published, "Final winner not released");

        uint256 _cash = 0;

        if (tokenId == winner1) {
            if (!bigWinnerReady[0]) revert("no fund or cashed out");
            // you lucky buster
            _cash += pool.mul(92).mul(50).div(10000).div(2);
            bigWinnerReady[0] = false;
        }
        if (tokenId == winner2) {
            if (!bigWinnerReady[1]) revert("no fund or cashed out");
            // you lucky buster two
            _cash += pool.mul(92).mul(50).div(10000).div(2);
            bigWinnerReady[1] = false;
        }

        // payable(msg.sender).transfer(_cash);
        (bool success, ) = msg.sender.call{value: _cash}("");
        require(success, "Claim transfer failed");

        emit cashedOut(msg.sender, tokenId, _cash);
    }

    function publicSaleMint(uint8 quantity) external onlyEOA nonReentrant {
        require(isPublicSaleActive(), "Public Sales Not Started");
        require(!isShowTimeStart(), "Public Sales Finished");
        require(
            balanceOf(msg.sender) + quantity <= 4,
            "max 4 public sale NFT allowed"
        );
        require(nfts.length + quantity <= MAX_SUPPLY, "max nft sold");

        _mint(msg.sender, quantity);
        for (uint8 i = 0; i < quantity; i++) nfts.push(0);
    }

    function bet(uint16 tokenId, uint8 _team)
        external
        payable
        onlyEOA
        nonReentrant
    {
        require(isShowTimeStart(), "Public Sales not Finished");
        require(_team < 32, "Only 32 teams support");
        require(_exists(tokenId), "token not exists");
        require(ownerOf(tokenId) == msg.sender, "Only owner");
        require(nfts[tokenId] & 0x20 == 0, "Bet token");
        require(msg.value >= _betPrice, "Insufficient Payment");

        nfts[tokenId] += _team | 0x20;
        gamblers.push(tokenId);

        // Refund overpayment
        if (msg.value > _betPrice) {
            (bool success, ) = msg.sender.call{value: msg.value.sub(_betPrice)}(
                ""
            );
            require(success, "Bet transfer failed");
        }

        pool += _betPrice;
    }

    // METADATA

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokensOf(address owner)
        public
        view
        onlyEOA
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i; i < count; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    // DISPLAY

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");

        if (!isShowTimeStart())
            return string(abi.encodePacked(_baseURI(), "cover.json"));
        else {
            uint24 value = nfts[tokenId];
            string memory team = _teamName[(value >> 15) & 0x1f];
            string memory no = _toString(uint256((value >> 6) & 0x1ff));
            string memory betTeam = "Not Bet";
            uint256 _id = ((value >> 15) & 0x1f) * 300 + ((value >> 6) & 0x1ff);

            string memory _name;
            if (value & 0x20 > 0) {
                betTeam = _teamName[value & 0x1f];
                _name = string(
                    abi.encodePacked(
                        "AzuGoal NFT #",
                        _toString(_id),
                        // ⭐️ = "\xe2\xad\x90\xef\xb8\x8f"
                        "\xe2\xad\x90\xef\xb8\x8f",
                        betTeam
                    )
                );
            } else
                _name = string(
                    abi.encodePacked("AzuGoal NFT #", _toString(_id))
                );

            bytes memory meta = abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "AzuGoal WorldCup 2022", "image": "',
                _baseURI(),
                _toString(_id),
                '.png", "designer": "isotop.top","attributes": [{"trait_type": "In-memory","value": "WorldCup 2022"}, {"trait_type": "Team","value": "',
                team,
                '"}, {"trait_type": "Number","value": "',
                no,
                '"}, {"trait_type": "Bet","value": "',
                betTeam,
                '"}]}'
            );

            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(meta)
                    )
                );
        }
    }

    function tokenInfo(uint256 tokenId)
        external
        view
        returns (
            uint256 _team,
            uint256 _no,
            uint256 _bet
        )
    {
        require(_exists(tokenId), "nonexistent token");

        uint24 value = nfts[tokenId];
        if (value & 0x20 > 0) _bet = uint256(value & 0x1f);
        else _bet = 32;
        _team = uint256((value >> 15) & 0x1f);
        _no = uint256((value >> 6) & 0x1ff);
    }

    function getRoundStatus(uint8 round)
        external
        view
        returns (Publish memory)
    {
        return publish[round];
    }

    function getFinalHolders() external view returns (uint16[] memory) {
        return finalHolders;
    }

    function getFinalWinners() external view returns (uint16[] memory) {
        return finalWinners;
    }

    function getBigWinners() external view returns (uint16, uint16) {
        return (winner1, winner2);
    }

    function getGamblers() external view returns (uint16[] memory) {
        return gamblers;
    }

    // OPERATORS
    function setWinner(uint8 round, uint8 _team) external onlyOperator {
        require(round < 64, "max 64 matchs");
        if (publish[round].published) revert("this round had published");

        if (
            publish[round].operator == ZERO ||
            publish[round].operator == msg.sender
        ) {
            publish[round] = Publish(_team, msg.sender, false);
            return;
        }

        if (publish[round].winner != _team) {
            publish[round].operator = msg.sender;
            publish[round].winner = _team;
            return;
        }

        for (uint16 i = 0; i < nfts.length; i++)
            if (((nfts[i] >> 15) & 0x1f) == _team) airDrops[i] += 1;

        publish[round].published = true;
    }

    function setFinalWinner(uint8 round, uint8 _team) external onlyOperator {
        require(round == 64, "final round must be 64 matchs");
        if (publish[round].published) revert("this round had published");

        if (
            publish[round].operator == ZERO ||
            publish[round].operator == msg.sender
        ) {
            publish[round] = Publish(_team, msg.sender, false);
            return;
        }

        if (publish[round].winner != _team) {
            publish[round].operator = msg.sender;
            publish[round].winner = _team;
            return;
        }
        uint256 length = nfts.length;

        for (uint16 i = 0; i < length; i++) {
            uint24 value = nfts[i];

            if (((value >> 15) & 0x1f) == _team) {
                airDrops[i] += 1;
                finalHolders.push(i);
                cashReady[i] = true;
            }
            if (value & 0x20 > 0 && (value & 0x1f == _team)) {
                finalWinners.push(i);
                cashReady[i] = true;
            }
        }

        if (finalWinners.length == 0) {
            publish[round].published = true;
            return;
        }

        if (finalWinners.length == 1) {
            winner1 = finalWinners[0];
            winner2 = finalWinners[0];
        } else if (finalWinners.length == 2) {
            winner1 = finalWinners[0];
            winner2 = finalWinners[1];
        } else {
            uint256 _random = block.timestamp;

            if (_vrfRequestId != 0) {
                (bool fulfilled, uint256[] memory randomWords) = vrf
                    .getRequestStatus(_vrfRequestId);
                if (fulfilled) _random = randomWords[1];
            }

            uint16[] memory _winners = vrf.shuffle16(
                uint16(finalWinners.length),
                _random
            );

            winner1 = finalWinners[_winners[0]];
            winner2 = finalWinners[_winners[1]];
        }

        bigWinnerReady[0] = true;
        bigWinnerReady[1] = true;

        emit winnerReleased(winner1, ownerOf(winner1));
        emit winnerReleased(winner2, ownerOf(winner2));

        publish[round].published = true;
        cashReady[MAX_SUPPLY] = true;
    }

    function startPublicSale() external onlyOperator {
        _publicSaleStart = block.timestamp;

        // We need 2 shuffle random seeds
        // 1: blind box
        // 2: final winner
        _vrfRequestId = vrf.requestRandomWords(2);

        emit publicSaleStart(block.timestamp);
    }

    function pausePublicSale() external onlyOperator {
        _publicSaleStart = FAR_FUTURE;
        emit publicSalePaused(block.timestamp);
    }

    function startShowTime() external onlyOperator {
        require(_showTimeStart == FAR_FUTURE, "Shuffle happened");

        _showTimeStart = block.timestamp;

        uint256 _random = block.timestamp;

        if (_vrfRequestId != 0) {
            (bool fulfilled, uint256[] memory randomWords) = vrf
                .getRequestStatus(_vrfRequestId);
            if (fulfilled) _random = randomWords[0];
        }

        uint16[] memory id = vrf.shuffle16(9600, _random);

        unchecked {
            for (uint256 i = 0; i < nfts.length; i++) {
                uint24 _team = id[i] / 300;
                uint24 _no = id[i] % 300;
                // 0x3ff = '0b11111111111111' (14bit)

                // save 5 bits for voting team, 1 bit for bet or not yet
                nfts[i] = (_team << 15) + (_no << 6);
            }
        }

        emit showTimeStart(block.timestamp);
    }

    // Team/Partnerships & Community
    function marketingMint(address to, uint16 quantity) external onlyOperator {
        require(!isShowTimeStart(), "Sales Finished");
        require(nfts.length + quantity <= MAX_SUPPLY, "max nft sold");

        _mint(to, quantity);
        for (uint8 i = 0; i < quantity; i++) nfts.push(0);
    }

    // OWNERS + HELPERS

    function setOperators(address[] calldata _operators) external onlyOwner {
        for (uint256 i = 0; i < _operators.length; i++)
            operators[_operators[i]] = true;
    }

    function setURInew(string memory uri)
        external
        onlyOwner
        returns (string memory)
    {
        _baseTokenURI = uri;
        emit baseUIRChanged(uri);
        return _baseTokenURI;
    }

    function setPrice(uint256 bet_price) external onlyOwner {
        _betPrice = bet_price;
    }

    function withdraw()
        external
        onlyOwner
        returns (uint256 split1, uint256 split2)
    {
        require(publish[64].published, "final winner not revealed");
        require(cashReady[MAX_SUPPLY], "cashed not ready or cashed out");

        uint256 total = pool.mul(8).div(100);

        split1 = total.mul(_share).div(1000);
        split2 = total - split1;

        (bool success1, ) = address(0x7B0dc23E87febF1D053E7Df9aF4cce30F21fAe9C)
            .call{value: split1}("");
        (bool success2, ) = address(0x9da32F03cc23F9156DaA7442cADbE8366ddAc123)
            .call{value: split2}("");
        require(success1 && success2, "withdraw transfer failed");

        cashReady[MAX_SUPPLY] = false;
        emit cashedOut(msg.sender, MAX_SUPPLY, total);
    }

    function getPool() external view onlyOwner returns (uint256) {
        return (pool);
    }

    function config()
        external
        view
        onlyOwner
        returns (
            address,
            address,
            address
        )
    {
        return (address(BEE_DDS_ADDRESS), address(vrf), address(aces));
    }

    function reset() external onlyOwner {
        selfdestruct(payable(0x7B0dc23E87febF1D053E7Df9aF4cce30F21fAe9C));
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}


// Generated by /Users/iwan/work/brownie/worldCup/scripts/functions.py
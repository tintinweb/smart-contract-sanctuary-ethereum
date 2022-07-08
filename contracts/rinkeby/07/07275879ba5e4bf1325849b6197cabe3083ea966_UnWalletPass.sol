// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./IERC2981.sol";
import "./Pausable.sol";
import "./ERC721Burnable.sol";
import "./Base64.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./IERC4907.sol";

contract UnWalletPass is ERC721Burnable, IERC2981, IERC4907, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    struct UserInfo {
        address user;
        uint64 expires;
    }

    uint256 public constant MAX_SUPPLY = 256;
    uint256 public constant RESERVED_SUPPLY = 32;
    uint256 public constant REQUIRED_BALANCE_FOR_MINTER = 0.1 ether;
    uint256 public constant ROYALTY_NUMERATOR = 250;
    uint256 public constant ROYALTY_DENOMINATOR = 10000;

    Counters.Counter private _tokenIDCounter;

    mapping(uint256 => address) private _firstOwners;
    mapping(uint256 => UserInfo) private _users;

    mapping(address => bool) private _isMinteds;

    constructor() ERC721("unWallet Pass", "UWPASS") {
        _tokenIDCounter._value = RESERVED_SUPPLY;

        _pause();
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceID == type(IERC2981).interfaceId ||
            interfaceID == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function firstOwnerOf(uint256 tokenID) external view returns (address) {
        address firstOwner = _firstOwners[tokenID];

        require(firstOwner != address(0), "UWP: invalid token ID");

        return firstOwner;
    }

    function mintByOwner(address to, uint256 tokenID) external onlyOwner {
        require(tokenID < RESERVED_SUPPLY, "UWP: unreserved token ID");

        _mint(to, tokenID);

        _firstOwners[tokenID] = to;
    }

    function mint() external whenNotPaused returns (uint256) {
        require(
            _tokenIDCounter.current() < MAX_SUPPLY,
            "UWP: reached max supply"
        );
        require(
            !_isMinteds[msg.sender],
            "UWP: you can only mint once per account"
        );
        require(
            msg.sender.balance >= REQUIRED_BALANCE_FOR_MINTER,
            string.concat(
                "UWP: minter must have at least ",
                REQUIRED_BALANCE_FOR_MINTER.toString(),
                " wei"
            )
        );

        uint256 tokenID = _tokenIDCounter.current();

        _isMinteds[msg.sender] = true;

        _mint(msg.sender, tokenID);

        _firstOwners[tokenID] = msg.sender;
        _tokenIDCounter.increment();

        return tokenID;
    }

    function tokenURI(uint256 tokenID)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenID);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name":"unWallet Pass #',
                                    tokenID.toString(),
                                    '",',
                                    '"image":"data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48c3ZnIGlkPSJ1dWlkLWVkMDA4NzcwLWViZmQtNGUyMy1hZTQ5LWRmMTk2Y2MxMWM3MiIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayIgdmlld0JveD0iMCAwIDEwODAgMTA4MCI+PGRlZnM+PHN0eWxlPi51dWlkLTVhMDg0NGNiLTQxMTQtNGZiYS1iN2E2LTUzYjExOTQ1NDIwMntmaWxsOm5vbmU7fS51dWlkLTY1Y2RjZWI1LWNmNWItNDkwMS1hMjE0LWJmMTExM2ExZmFkOHtmaWxsOiMwMDkzYTU7fS51dWlkLWUxZjNhMmQ3LWQ3MGMtNGFlYS05YjBjLWNmYmUzYTJiYThhZHtmaWxsOiNlNmU2ZTY7fS51dWlkLWRhNzUwZmNiLTYzNTAtNGJhNC04ZWYwLTMxZjU1ZWMyNWM1MHtmaWxsOiNmZmY7ZmlsdGVyOnVybCgjdXVpZC03NGI0NjExZi03NTJlLTRiYzAtYjA3Ny0zOTg2MmZjYjQ2ODApO3N0cm9rZTojZTZlNmU2O3N0cm9rZS1taXRlcmxpbWl0OjEwO3N0cm9rZS13aWR0aDo4cHg7fS51dWlkLTQ5ZjlkMDZhLTIwNWItNDEyNS04Zjg4LWE3MzY4YWEyM2I1MntvcGFjaXR5Oi44O308L3N0eWxlPjxmaWx0ZXIgaWQ9InV1aWQtNzRiNDYxMWYtNzUyZS00YmMwLWIwNzctMzk4NjJmY2I0NjgwIiBmaWx0ZXJVbml0cz0idXNlclNwYWNlT25Vc2UiPjxmZU9mZnNldCBkeD0iMiIgZHk9IjIiLz48ZmVHYXVzc2lhbkJsdXIgcmVzdWx0PSJ1dWlkLTJjMzFmMGFlLTg2NzItNDViMS1hMDczLWNiMDZjYmQzNWQ0OCIgc3RkRGV2aWF0aW9uPSI2Ii8+PGZlRmxvb2QgZmxvb2QtY29sb3I9IiMwMDkzYTUiIGZsb29kLW9wYWNpdHk9IjEiLz48ZmVDb21wb3NpdGUgaW4yPSJ1dWlkLTJjMzFmMGFlLTg2NzItNDViMS1hMDczLWNiMDZjYmQzNWQ0OCIgb3BlcmF0b3I9ImluIi8+PGZlQ29tcG9zaXRlIGluPSJTb3VyY2VHcmFwaGljIi8+PC9maWx0ZXI+PC9kZWZzPjxnPjxyZWN0IGNsYXNzPSJ1dWlkLWRhNzUwZmNiLTYzNTAtNGJhNC04ZWYwLTMxZjU1ZWMyNWM1MCIgeD0iMjI2IiB5PSIzMzguMTgiIHdpZHRoPSI2NDAuOTkiIGhlaWdodD0iNDA0LjIyIiByeD0iMjQiIHJ5PSIyNCIvPjxnIGNsYXNzPSJ1dWlkLTQ5ZjlkMDZhLTIwNWItNDEyNS04Zjg4LWE3MzY4YWEyM2I1MiI+PHBhdGggY2xhc3M9InV1aWQtNjVjZGNlYjUtY2Y1Yi00OTAxLWEyMTQtYmYxMTEzYTFmYWQ4IiBkPSJNNTYxLjMyLDU1NC4yNmM0LjYzLTQuODQsNy40Ny0xMS40LDcuNDctMTguNjIsMC05LjYtNS4wMi0xOC4wMy0xMi41OC0yMi44MWw4Ljc2LTE2LjczYy41NCwuMTEsMS4xLC4xNywxLjY3LC4xNyw0LjQzLDAsOC4wMi0zLjU5LDguMDItOC4wMXMtMy41OC04LjAxLTguMDItOC4wMS04LjAyLDMuNTktOC4wMiw4LjAxYzAsMi4zLC45Nyw0LjM3LDIuNTIsNS44NGwtOC43NiwxNi43M2MtMy4yNC0xLjM5LTYuODEtMi4xNS0xMC41Ni0yLjE1LTE0Ljg5LDAtMjYuOTYsMTIuMDctMjYuOTYsMjYuOTcsMCw2Ljc4LDIuNSwxMi45Nyw2LjYzLDE3LjdsLTE0LjQ1LDE0Ljc3Yy0yLjIzLTEuNTctNC45NS0yLjUtNy44OS0yLjUtNy41NCwwLTEzLjY1LDYuMTEtMTMuNjUsMTMuNjUsMCw3LjU0LDYuMTEsMTMuNjYsMTMuNjUsMTMuNjZzMTMuNjUtNi4xMSwxMy42NS0xMy42NmMwLTMuMDQtLjk5LTUuODUtMi42OC04LjEybDE0LjQ1LTE0Ljc4YzQuNjgsMy45LDEwLjY5LDYuMjQsMTcuMjUsNi4yNCw2LjExLDAsMTEuNzUtMi4wMywxNi4yNy01LjQ2bS0xNi4yNy04Ljk0Yy0yLjY0LDAtNS4wOC0uODEtNy4xMS0yLjIxLTEuMTktLjgyLTIuMjQtMS44NS0zLjA5LTMuMDMtMS40OS0yLjA2LTIuMzctNC41OS0yLjM3LTcuMzMsMC02LjkzLDUuNjMtMTIuNTYsMTIuNTYtMTIuNTYsMS4zMywwLDIuNjIsLjIxLDMuODMsLjYsMS40LC40NSwyLjY5LDEuMTMsMy44MiwyLjAxLDIuOTksMi4zMSw0LjkyLDUuOTEsNC45Miw5Ljk1LDAsMi45NC0xLjAyLDUuNjUtMi43Myw3Ljc5LS45LDEuMTMtMS45OCwyLjExLTMuMjIsMi44OC0xLjkyLDEuMTktNC4xOSwxLjg5LTYuNjIsMS44OVoiLz48cmVjdCBjbGFzcz0idXVpZC02NWNkY2ViNS1jZjViLTQ5MDEtYTIxNC1iZjExMTNhMWZhZDgiIHg9IjU2Ni44MiIgeT0iNTM4LjUiIHdpZHRoPSIxMy42MiIgaGVpZ2h0PSI2NS41MyIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTIzNC40NyA1MjIuNjUpIHJvdGF0ZSgtNDEuNDQpIi8+PHJlY3QgY2xhc3M9InV1aWQtNjVjZGNlYjUtY2Y1Yi00OTAxLWEyMTQtYmYxMTEzYTFmYWQ4IiB4PSI1ODAuNDciIHk9IjU1NC45NCIgd2lkdGg9IjExLjY0IiBoZWlnaHQ9IjIzLjA4IiB0cmFuc2Zvcm09InRyYW5zbGF0ZSg2MjIuOTQgLTI0Ny45NSkgcm90YXRlKDQ4LjU2KSIvPjxyZWN0IGNsYXNzPSJ1dWlkLTY1Y2RjZWI1LWNmNWItNDkwMS1hMjE0LWJmMTExM2ExZmFkOCIgeD0iNTk1LjE3IiB5PSI1NzEuNTEiIHdpZHRoPSIxMS42NCIgaGVpZ2h0PSIyMy4wOCIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoNjQwLjM0IC0yNTMuMzYpIHJvdGF0ZSg0OC41NikiLz48L2c+PHBvbHlnb24gY2xhc3M9InV1aWQtZTFmM2EyZDctZDcwYy00YWVhLTliMGMtY2ZiZTNhMmJhOGFkIiBwb2ludHM9IjgzNi45OSA1NDAuMjkgODIwLjc4IDUyNS44NSA4MjAuNzggNTU0LjcyIDgzNi45OSA1NDAuMjkiLz48L2c+PHJlY3QgY2xhc3M9InV1aWQtNWEwODQ0Y2ItNDExNC00ZmJhLWI3YTYtNTNiMTE5NDU0MjAyIiB3aWR0aD0iMTA4MCIgaGVpZ2h0PSIxMDgwIi8+PC9zdmc+",',
                                    '"attributes":[{"trait_type":"Type","value":"Genesis"}]}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function setUser(
        uint256 tokenID,
        address user,
        uint64 expires
    ) external {
        require(
            _isApprovedOrOwner(msg.sender, tokenID),
            "UWP: caller is not token owner nor approved"
        );

        UserInfo storage userInfo = _users[tokenID];
        userInfo.user = user;
        userInfo.expires = expires;

        emit UpdateUser(tokenID, user, expires);
    }

    function userOf(uint256 tokenID) external view returns (address) {
        _requireMinted(tokenID);

        if (block.timestamp >= uint256(_users[tokenID].expires)) {
            return address(0);
        }

        return _users[tokenID].user;
    }

    function userExpires(uint256 tokenID) external view returns (uint256) {
        _requireMinted(tokenID);

        return _users[tokenID].expires;
    }

    function royaltyInfo(uint256 tokenID, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        _requireMinted(tokenID);

        return (owner(), (salePrice * ROYALTY_NUMERATOR) / ROYALTY_DENOMINATOR);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenID
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenID);

        if (from != to && _users[tokenID].user != address(0)) {
            delete _users[tokenID];

            emit UpdateUser(tokenID, address(0), 0);
        }
    }
}
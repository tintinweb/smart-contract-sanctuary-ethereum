//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControlEnumerable.sol";
import "./IERC20.sol";
import "./ERC2981.sol";

contract VegaNFT is
    ERC721Enumerable,
    ERC721URIStorage,
    ERC2981,
    AccessControlEnumerable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // mapping cashback to addresses and their values
    mapping(uint256 => address[]) private _cashbackRecipients;
    mapping(uint256 => uint256[]) private _cashbackValues;
    mapping(uint256 => address) private _customToken;
    bool _publicMint;
    constructor(string memory name_, string memory symbol_,bool publicMint)
        ERC721(name_, symbol_)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _publicMint=publicMint;
    }

    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @param uri The token URI of the minted token.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintWithTokenURI(
        address to,
        uint256 tokenId,
        string memory uri
    ) public returns (bool) {
        if(!_publicMint){
            require(
                hasRole(MINTER_ROLE, _msgSender()),
                "ERC721PresetMinterPauserAutoId: must have minter role to mint"
            );
        }
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return true;
    }
    function royaltyInfo(uint256 tokenId, uint256 value)
            external
            view
            override
            returns (address, uint256)
        {
            require(value >= 1, "value should be greater than or equal to 1");
            return (_cashbackRecipients[tokenId][0], _cashbackValues[tokenId][0]);
        }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function tokenCashbackValues(uint256 tokenId, uint256 tokenPrice)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return _cashbackValues[tokenId];
    }

    function tokenCashbackRecipients(uint256 tokenId)
        public
        view
        virtual
        returns (address[] memory)
    {
        return _cashbackRecipients[tokenId];
    }

    function allowance(address a, uint256 t) public view returns (bool) {
        return _isApprovedOrOwner(a, t);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        return ERC721URIStorage._burn(tokenId);
    }

    function mintMultiple(
        address[] memory to,
        uint256[] memory tokenId,
        string[] memory uri
    ) public returns (bool) {
        if(!_publicMint){
            require(
                hasRole(MINTER_ROLE, _msgSender()),
                "ERC721PresetMinterPauserAutoId: must have minter role to mint"
            );
        }
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], tokenId[i]);
            _setTokenURI(tokenId[i], uri[i]);
        }
        return true;
    }

    function updateCashbackForAuthor(uint256 tokenId, uint256 cashbackValue)
        public
        returns (bool)
    {
        for (uint256 i = 0; i < _cashbackValues[tokenId].length; i++) {
            if (_cashbackRecipients[tokenId][i] == _msgSender()) {
                _cashbackValues[tokenId][i] = cashbackValue;
                return true;
            }
        }
        return true;
    }

    function getCashbackAddress(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        return _customToken[tokenId];
    }

    function mintMultipleCashback(
        address[] memory to,
        uint256[] memory tokenId,
        string[] memory uri,
        address[][] memory recipientAddresses,
        uint256[][] memory cashbackValues,
        address erc20
    ) public returns (bool) {
        require(
            erc20 != address(0),
            "Custom cashbacks cannot be set to 0 address"
        );
        for (uint256 i = 0; i < tokenId.length; i++) {
            _customToken[tokenId[i]] = erc20;
        }
        return
            mintMultipleCashback(
                to,
                tokenId,
                uri,
                recipientAddresses,
                cashbackValues
            );
    }

    function mintMultipleCashback(
        address[] memory to,
        uint256[] memory tokenId,
        string[] memory uri,
        address[][] memory recipientAddresses,
        uint256[][] memory cashbackValues
    ) public returns (bool) {
        if(!_publicMint){
            require(
                hasRole(MINTER_ROLE, _msgSender()),
                "ERC721PresetMinterPauserAutoId: must have minter role to mint"
            );
        }
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], tokenId[i]);
            _setTokenURI(tokenId[i], uri[i]);
            _cashbackRecipients[tokenId[i]] = recipientAddresses[i];
            _cashbackValues[tokenId[i]] = cashbackValues[i];
        }
        return true;
    }

    function mintWithCashback(
        address to,
        uint256 tokenId,
        string memory uri,
        address[] memory recipientAddresses,
        uint256[] memory cashbackValues,
        address erc20
    ) public returns (bool) {
        require(
            erc20 != address(0),
            "Custom cashbacks cannot be set to 0 address"
        );
        _customToken[tokenId] = erc20;
        return
            mintWithCashback(
                to,
                tokenId,
                uri,
                recipientAddresses,
                cashbackValues
            );
    }

    function mintWithCashback(
        address to,
        uint256 tokenId,
        string memory uri,
        address[] memory recipientAddresses,
        uint256[] memory cashbackValues
    ) public returns (bool) {
        if(!_publicMint){
            require(
                hasRole(MINTER_ROLE, _msgSender()),
                "ERC721PresetMinterPauserAutoId: must have minter role to mint"
            );
        }
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        // saving cashback addresses and values
        _cashbackRecipients[tokenId] = recipientAddresses;
        _cashbackValues[tokenId] = cashbackValues;
        return true;
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function safeTransfer(address to, uint256 tokenId) public payable {
        address erc = _customToken[tokenId];
        IERC20 token;
        if (erc != address(0)) {
            token = IERC20(erc);
        }
        if (_cashbackRecipients[tokenId].length != 0) {
            // checking cashback addresses exists and sum of cashbacks
            require(
                _cashbackRecipients[tokenId].length != 0,
                "CashbackToken should be of cashback type"
            );
            uint256 sum = 0;
            for (uint256 i = 0; i < _cashbackValues[tokenId].length; i++) {
                sum += _cashbackValues[tokenId][i];
            }
            if (erc == address(0)) {
                if (sum > msg.value) {
                    payable(msg.sender).transfer(msg.value);
                    revert(
                        "Value should be greater than or equal to cashback value"
                    );
                }
                for (
                    uint256 i = 0;
                    i < _cashbackRecipients[tokenId].length;
                    i++
                ) {
                    // transferring cashback to authors
                    if (_cashbackValues[tokenId][i] > 0) {
                        payable(_cashbackRecipients[tokenId][i]).transfer(
                            _cashbackValues[tokenId][i]
                        );
                    }
                }
                if (msg.value > sum) {
                    payable(msg.sender).transfer(msg.value - sum);
                }
            } else {
                if (sum > token.allowance(_msgSender(), address(this))) {
                    revert(
                        "Insufficient ERC20 allowance balance for paying for the asset."
                    );
                }
                for (
                    uint256 i = 0;
                    i < _cashbackRecipients[tokenId].length;
                    i++
                ) {
                    // transferring cashback to authors
                    if (_cashbackValues[tokenId][i] > 0) {
                        token.transferFrom(
                            _msgSender(),
                            to,
                            _cashbackValues[tokenId][i]
                        );
                    }
                }
                if (msg.value > 0) {
                    payable(_msgSender()).transfer(msg.value);
                }
            }
            _safeTransfer(_msgSender(), to, tokenId, "");
        } else {
            if (msg.value > 0) {
                payable(msg.sender).transfer(msg.value);
            }
            _safeTransfer(_msgSender(), to, tokenId, "");
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory bytesData
    ) public payable virtual override {
        address erc = _customToken[tokenId];
        IERC20 token;
        if (erc != address(0)) {
            token = IERC20(erc);
        }
        if (_cashbackRecipients[tokenId].length != 0) {
            // checking cashback addresses exists and sum of cashbacks
            require(
                _cashbackRecipients[tokenId].length != 0,
                "CashbackToken should be of cashback type"
            );
            uint256 sum = 0;
            for (uint256 i = 0; i < _cashbackValues[tokenId].length; i++) {
                sum += _cashbackValues[tokenId][i];
            }
            if (erc == address(0)) {
                if (sum > msg.value) {
                    payable(from).transfer(msg.value);
                    revert(
                        "Value should be greater than or equal to cashback value"
                    );
                }
                for (
                    uint256 i = 0;
                    i < _cashbackRecipients[tokenId].length;
                    i++
                ) {
                    // transferring cashback to authors
                    if (_cashbackValues[tokenId][i] > 0) {
                        payable(_cashbackRecipients[tokenId][i]).transfer(
                            _cashbackValues[tokenId][i]
                        );
                    }
                }
                if (msg.value > sum) {
                    payable(from).transfer(msg.value - sum);
                }
            } else {
                if (sum > token.allowance(to, address(this))) {
                    revert(
                        "Insufficient ERC20 allowance balance for paying for the asset."
                    );
                }
                for (
                    uint256 i = 0;
                    i < _cashbackRecipients[tokenId].length;
                    i++
                ) {
                    // transferring cashback to authors
                    if (_cashbackValues[tokenId][i] > 0) {
                        token.transferFrom(
                            to,
                            _cashbackRecipients[tokenId][i],
                            _cashbackValues[tokenId][i]
                        );
                    }
                }
                if (msg.value > 0) {
                    payable(msg.sender).transfer(msg.value);
                }
            }
            _safeTransfer(from, to, tokenId, bytesData);
        } else {
            if (msg.value > 0) {
                payable(from).transfer(msg.value);
            }
            _safeTransfer(from, to, tokenId, bytesData);
        }
    }
}
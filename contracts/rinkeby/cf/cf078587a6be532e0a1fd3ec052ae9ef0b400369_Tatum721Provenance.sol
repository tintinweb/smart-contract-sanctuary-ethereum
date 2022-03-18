//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControlEnumerable.sol";
import "./IERC20.sol";
import "./ERC2981.sol";
contract Tatum721Provenance is
    ERC721Enumerable,
    ERC2981,
    ERC721URIStorage,
    AccessControlEnumerable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(uint256 => string[]) private _tokenData;
    mapping(uint256 => address[]) private _cashbackRecipients;
    mapping(uint256 => uint256[]) private _cashbackValues;
    mapping(uint256 => uint256[]) private _fixedValues;
    mapping(uint256 => address) private _customToken;
    bool _publicMint;
    event TransferWithProvenance(
        uint256 indexed id,
        address owner,
        string data,
        uint256 value
    );

    constructor(string memory name_, string memory symbol_, bool publicMint)
        ERC721(name_, symbol_)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _publicMint=publicMint;
    }
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address, uint256)
    {
        uint256 result;
        uint256 cbvalue = (_cashbackValues[tokenId][0] * value) / 10000;
        result=_cashbackCalculator(cbvalue,_fixedValues[tokenId][0]);
        return (_cashbackRecipients[tokenId][0],result);
    }
    function _appendTokenData(uint256 tokenId, string calldata tokenData)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenData[tokenId].push(tokenData);
    }

    function mintWithTokenURI(
        address to,
        uint256 tokenId,
        string memory uri,
        address[] memory recipientAddresses,
        uint256[] memory cashbackValues,
        uint256[] memory fValues,
        address erc20
    ) public {
        require(
            erc20 != address(0),
            "Custom cashbacks cannot be set to 0 address"
        );
        _customToken[tokenId] = erc20;
        return
            mintWithTokenURI(
                to,
                tokenId,
                uri,
                recipientAddresses,
                cashbackValues,
                fValues
            );
    }

    function mintWithTokenURI(
        address to,
        uint256 tokenId,
        string memory uri,
        address[] memory recipientAddresses,
        uint256[] memory cashbackValues,
        uint256[] memory fValues
    ) public {
        if(!_publicMint){
            require(
                hasRole(MINTER_ROLE, _msgSender()),
                "ERC721PresetMinterPauserAutoId: must have minter role to mint"
            );
        }
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        // saving cashback addresses and values
        if (recipientAddresses.length > 0) {
            _cashbackRecipients[tokenId] = recipientAddresses;
            _cashbackValues[tokenId] = cashbackValues;
            _fixedValues[tokenId] = fValues;
        }
    }

    function mintMultiple(
        address[] memory to,
        uint256[] memory tokenId,
        string[] memory uri,
        address[][] memory recipientAddresses,
        uint256[][] memory cashbackValues,
        uint256[][] memory fValues,
        address erc20
    ) public {
        require(
            erc20 != address(0),
            "Custom cashbacks cannot be set to 0 address"
        );
        for (uint256 i; i < to.length; i++) {
            _customToken[tokenId[i]] = erc20;
        }
        return
            mintMultiple(
                to,
                tokenId,
                uri,
                recipientAddresses,
                cashbackValues,
                fValues
            );
    }

    function mintMultiple(
        address[] memory to,
        uint256[] memory tokenId,
        string[] memory uri,
        address[][] memory recipientAddresses,
        uint256[][] memory cashbackValues,
        uint256[][] memory fValues
    ) public {
        if(!_publicMint){
            require(
                hasRole(MINTER_ROLE, _msgSender()),
                "ERC721PresetMinterPauserAutoId: must have minter role to mint"
            );
        }
        for (uint256 i; i < to.length; i++) {
            _mint(to[i], tokenId[i]);
            _setTokenURI(tokenId[i], uri[i]);
            if (
                recipientAddresses.length > 0 &&
                recipientAddresses[i].length > 0
            ) {
                _cashbackRecipients[tokenId[i]] = recipientAddresses[i];
                _cashbackValues[tokenId[i]] = cashbackValues[i];
                _fixedValues[tokenId[i]] = fValues[i];
            }
        }
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

    function getCashbackAddress(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        return _customToken[tokenId];
    }

    function getTokenData(uint256 tokenId)
        public
        view
        virtual
        returns (string[] memory)
    {
        return _tokenData[tokenId];
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

    function tokenCashbackValues(uint256 tokenId, uint256 tokenPrice)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256[] memory result=_cashbackValues[tokenId];
        for(uint i=0;i<result.length;i++){
            uint256 cbvalue = (result[i] * tokenPrice) / 10000;
            result[i]=_cashbackCalculator(cbvalue,_fixedValues[tokenId][i]);
        }
        return result;
    }

    function tokenCashbackRecipients(uint256 tokenId)
        public
        view
        virtual
        returns (address[] memory)
    {
        return _cashbackRecipients[tokenId];
    }

    function updateCashbackForAuthor(uint256 tokenId, uint256 cashbackValue)
        public
    {
        for (uint256 i; i < _cashbackValues[tokenId].length; i++) {
            if (_cashbackRecipients[tokenId][i] == _msgSender()) {
                _cashbackValues[tokenId][i] = cashbackValue;
            }
        }
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function _stringToUint(string memory s)
        internal
        pure
        returns (uint256 result)
    {
        bytes memory b = bytes(s);
        // result = 0;
        for (uint256 i; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function allowance(address a, uint256 t) public view returns (bool) {
        return _isApprovedOrOwner(a, t);
    }

    function safeTransfer(
        address to,
        uint256 tokenId,
        bytes calldata dataBytes
    ) public payable {
        uint256 index;
        uint256 value;
        uint256 percentSum;
        IERC20 token;
        (index, value) = _bytesCheck(dataBytes);
        if (_customToken[tokenId] != address(0)) {
            token = IERC20(_customToken[tokenId]);
        }
        if (_cashbackRecipients[tokenId].length > 0) {
            for (uint256 i = 0; i < _cashbackValues[tokenId].length; i++) {
                uint256 iPercent = (_cashbackValues[tokenId][i] * value) /
                    10000;
                if (iPercent >= _fixedValues[tokenId][i]) {
                    percentSum += iPercent;
                } else {
                    percentSum += _fixedValues[tokenId][i];
                }
            }
            if (_customToken[tokenId] == address(0)) {
                if (percentSum > msg.value) {
                    payable(msg.sender).transfer(msg.value);
                    revert(
                        "Value should be greater than or equal to cashback value"
                    );
                }
            } else {
                if (percentSum > token.allowance(to, address(this))) {
                    revert(
                        "Insufficient ERC20 allowance balance for paying for the asset."
                    );
                }
            }
            for (uint256 i = 0; i < _cashbackRecipients[tokenId].length; i++) {
                // transferring cashback to authors
                uint256 cbvalue = (_cashbackValues[tokenId][i] * value) / 10000;
                if (_customToken[tokenId] == address(0)) {
                    cbvalue = _cashbackCalculator(
                        cbvalue,
                        _fixedValues[tokenId][i]
                    );
                    payable(_cashbackRecipients[tokenId][i]).transfer(cbvalue);
                } else {
                    cbvalue = _cashbackCalculator(
                        cbvalue,
                        _fixedValues[tokenId][i]
                    );
                    token.transferFrom(
                        to,
                        _cashbackRecipients[tokenId][i],
                        cbvalue
                    );
                }
            }
            if(_customToken[tokenId] == address(0) && msg.value>percentSum){
                payable(msg.sender).transfer(msg.value - percentSum);
            }
            if(_customToken[tokenId] != address(0) && msg.value>0){
                    payable(msg.sender).transfer(msg.value);
            }
        }
        _safeTransfer(msg.sender, to, tokenId, dataBytes);
        string calldata dataString = string(dataBytes);
        _appendTokenData(tokenId, dataString);
        emit TransferWithProvenance(tokenId, to, dataString[:index], value);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata dataBytes
    ) public payable virtual override {
        uint256 index;
        uint256 value;
        uint256 percentSum;
        IERC20 token;
        (index, value) = _bytesCheck(dataBytes);
        if (_customToken[tokenId] != address(0)) {
            token = IERC20(_customToken[tokenId]);
        }
        //Error Below This Line
        if (_cashbackRecipients[tokenId].length > 0) {
            //error is above this line
            for (uint256 i = 0; i < _cashbackValues[tokenId].length; i++) {
                uint256 iPercent = (_cashbackValues[tokenId][i] * value) /
                    10000;
                    //error is above this line
                if (iPercent >= _fixedValues[tokenId][i]) {
                    percentSum += iPercent;
                } else {
                    //error is above this line
                    percentSum += _fixedValues[tokenId][i];
                }
            }
            //Error above this line
            if (_customToken[tokenId] == address(0)) {
                if (percentSum > msg.value) {
                    payable(from).transfer(msg.value);
                    revert(
                        "Value should be greater than or equal to cashback value"
                    );
                }
            } //else {
                //Error above this line
                /*
                if (percentSum > token.allowance(to, address(this))) {
                    revert(
                        "Insufficient ERC20 allowance balance for paying for the asset."
                    );
                }*/
           // }
            //error above this line
            for (uint256 i = 0; i < _cashbackRecipients[tokenId].length; i++) {
                // transferring cashback to authors
                uint256 cbvalue = (_cashbackValues[tokenId][i] * value) / 10000;
                if (_customToken[tokenId] == address(0)) {
                    cbvalue = _cashbackCalculator(
                        cbvalue,
                        _fixedValues[tokenId][i]
                    );
                    payable(_cashbackRecipients[tokenId][i]).transfer(cbvalue);
                } else {
                    cbvalue = _cashbackCalculator(
                        cbvalue,
                        _fixedValues[tokenId][i]
                    );
                    
                    /*
                    if (!token.transfer(_cashbackRecipients[tokenId][i], cbvalue)) {
                        revert("Something went wrong trying to transfer the royalties to the recipients.");
                    }
                    
                    //token.transfer(_cashbackRecipients[tokenId][i], cbvalue);
                    
                    token.transferFrom(
                        address(this),
                        _cashbackRecipients[tokenId][i],
                        cbvalue
                    );*/
                    token.approve(address(this), 100);
                    if (!token.transferFrom(address(this), _cashbackRecipients[tokenId][i], cbvalue)) {
                        revert("SOMETHING WENT WRONG PAYING ROYALTIES");
                    }
                }
            }
            if(_customToken[tokenId] != address(0) && msg.value>0){
                    payable(from).transfer(msg.value);
            }
            if(_customToken[tokenId] == address(0) && msg.value>percentSum){
                payable(from).transfer(msg.value - percentSum);
            }
        }
        _safeTransfer(from, to, tokenId, dataBytes);
        string calldata dataString = string(dataBytes);
        _appendTokenData(tokenId, dataString);
        emit TransferWithProvenance(tokenId, to, dataString[:index], value);
    }

    function _cashbackCalculator(uint256 x, uint256 y)
        private
        pure
        returns (uint256)
    {
        if (x >= y) {
            return x;
        }
        return y;
    }

    function _bytesCheck(bytes calldata dataBytes)
        private
        pure
        returns (uint256 index, uint256 value)
    {
        for (uint256 i = 0; i < dataBytes.length; i++) {
            if (
                dataBytes[i] == 0x27 &&
                dataBytes.length > i + 8 &&
                dataBytes[i + 1] == 0x27 &&
                dataBytes[i + 2] == 0x27 &&
                dataBytes[i + 3] == 0x23 &&
                dataBytes[i + 4] == 0x23 &&
                dataBytes[i + 5] == 0x23 &&
                dataBytes[i + 6] == 0x27 &&
                dataBytes[i + 7] == 0x27 &&
                dataBytes[i + 8] == 0x27
            ) {
                index = i;
                bytes calldata valueBytes = dataBytes[index + 9:];
                value = _stringToUint(string(valueBytes));
            }
        }
    }
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TX {

    struct Token{
        uint256 fee; // comission for transfer
        bool kindFee; // if this parametr is true - the fee is a percentage
        //if this parametr is false - commision is a number
    }

    mapping (address => Token) public token;

    address public owner; // contract owner
    address payable public vault; // address which will get fees
    uint256 public etherFee; // fix number
    uint256 public tokenFee;

    event TransferTokens(address indexed tokenAddress, address indexed from, address indexed to, uint256 amount);
    event TransferTokenComission(address indexed tokenAddress, address indexed from, address indexed to, uint256 amount);
    event TransferEther(address indexed from, address indexed to, uint256 indexed amount);
    event TransferEtherComission(address indexed from, address indexed to, uint256 indexed amount);
    event AddToken(address indexed tokenAddress, uint256 indexed fee, bool indexed kindFee);
    event SetFee(address indexed tokenAddress, uint256 indexed fee);
    event SetKindFee(address indexed tokenAddress, uint256 indexed fee, bool kindFee);
    event SetEtherFee(uint256 indexed etherFee);
    event SetOwner(address indexed owner);
    event SetVault(address indexed vault);

    constructor(
        address owner_,
        address payable vault_,
        uint256 etherFee_,
        address[] memory tokenAddresses_,
        uint256[] memory fees_,
        bool[] memory kindFees_,
        uint256 tokenFee_
    ) {
        owner = owner_;
        vault = vault_;
        etherFee = etherFee_;
        uint256 size_ = tokenAddresses_.length;
        tokenFee = tokenFee_;
    
        for (uint256 i = 0; i < size_;) {
            token[tokenAddresses_[i]] = Token({
            fee: fees_[i],
            kindFee: kindFees_[i]
            });
            unchecked { ++i; } // lower gas
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function txTokens(address[] calldata _tokenAdresses, address[] calldata _addresses, uint256[] calldata _amounts) external {
        address _msgSender = msg.sender;
        uint256 _size = _addresses.length;
        require
        (
            _size == _amounts.length,
            "Not same lenght of _addresses and _amounts"
        );

        require
        (
            _size == _tokenAdresses.length,
            "Not same lenght of _addresses and _amounts"
        );

        uint256 _comission;
        address _tokenAddress;
        address _userAddress;
        uint256 _userAmount;

        for (uint256 i = 0; i < _size;) {
            _tokenAddress = _tokenAdresses[i];
            _userAddress = _addresses[i];
            _userAmount = _amounts[i];

            if 
            (
                _userAmount > 0 && 
                token[_tokenAddress].fee > 0 &&
                IERC20(_tokenAddress).balanceOf(_msgSender) >= _userAmount
                
            ) {
                if (token[_tokenAddress].kindFee) {
                    _comission = _userAmount * token[_tokenAddress].fee / 100;
                } else {
                    _comission = token[_tokenAddress].fee;
                }
                
                _userAmount -= _comission;
                IERC20(_tokenAddress).transferFrom(_msgSender, _userAddress, _userAmount);
                IERC20(_tokenAddress).transferFrom(_msgSender, vault, _comission);

                emit TransferTokens(_tokenAddress, _msgSender, _userAddress, _userAmount);
                emit TransferTokenComission(_tokenAddress, _msgSender, vault, _comission);
        }
        unchecked { ++i; } // lower gas
    }
}
    function txTokensV2(IERC20[] calldata _tokenAdresses, address[] calldata _addresses, uint256[] calldata _amounts) external {
        address _msgSender = msg.sender;
        uint256 _size = _addresses.length;
        require
        (
            _size == _amounts.length,
            "Not same lenght of _addresses and _amounts"
        );
        require
        (
            _size == _tokenAdresses.length,
            "Not same lenght of _addresses and _amounts"
        );
        IERC20 _tokenAddress;
        uint256 _userAmount;
        for (uint256 i = 0; i < _size;) {
            _tokenAddress = _tokenAdresses[i];
            _userAmount = _amounts[i];
            if 
            (
                _userAmount > 0 && 
                _tokenAddress.balanceOf(_msgSender) >= _userAmount
            ) {
                _tokenAddress.transferFrom(_msgSender, _addresses[i], _userAmount -= tokenFee);
                _tokenAddress.transferFrom(_msgSender, vault, tokenFee);
        }
        unchecked { ++i; } // lower gas
        }
    }


    function txEther(address payable[] calldata _addresses, uint256[] calldata _amounts) payable external {
        address _msgSender = msg.sender; // lower gas
        uint256 _msgValue = msg.value;
        require(_msgValue > 0, "Zero ether");
        uint256 _size = _addresses.length;
        require
        (
            _size == _amounts.length,
            "Not same lenght of _addresses and _amounts"
        );
        
        uint256 _userAmount;
        uint256 _realUserAmount;
        bool _sent;
        address payable _userAddress;

        for (uint256 i = 0; i < _size;) {
            _userAmount = _amounts[i];
            require(_msgValue >= _userAmount, "Not enough ether");
            _userAddress = _addresses[i];
            
            _msgValue -= _userAmount;
            _realUserAmount = _userAmount - etherFee;
            _sent = _userAddress.send(_realUserAmount);
            emit TransferEther(_msgSender, _userAddress, _realUserAmount);
            unchecked { ++i; } // lower gas
        }
        _sent = vault.send(_size * etherFee);
        emit TransferEtherComission(_msgSender, vault, _size * etherFee);

    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Withdrawable: Amount has to be greater than 0");
        require(
            _amount <= address(this).balance,
            "Withdrawable: Not enough funds"
        );
        payable(msg.sender).transfer(_amount);
    }

    function addToken(address _tokenAddress, uint256 _fee, bool _kindFee) external onlyOwner{
        require(token[_tokenAddress].fee == 0, "This token already added");
        require(_fee > 0, "Zero fee");
        token[_tokenAddress] = Token({
            fee: _fee,
            kindFee: _kindFee
        });
        emit AddToken(_tokenAddress, _fee, _kindFee);
    }

    function setFee(address _tokenAddress, uint256 _fee) external onlyOwner {
        require(token[_tokenAddress].fee > 0, "Token not added");
        require(_fee > 0, "Zero fee");
        token[_tokenAddress].fee = _fee;
        emit SetFee(_tokenAddress, _fee);
    }

    function setKindFee(address _tokenAddress, uint256 _fee, bool _kindFee) external onlyOwner {
        require(token[_tokenAddress].fee > 0, "Token not added");
        require(_fee > 0, "Zero fee");
        token[_tokenAddress].fee = _fee;
        token[_tokenAddress].kindFee = _kindFee;
        emit SetKindFee(_tokenAddress, _fee, _kindFee);
    }

    function setEtherFee(uint256 _etherFee) external onlyOwner {
        require(_etherFee > 0, "Zero fee");
        etherFee = _etherFee;
        emit SetEtherFee(etherFee);

    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit SetOwner(owner);
    }

    function setVault(address payable _newVault) external onlyOwner {
        vault = _newVault;
        emit SetVault(vault);
    }

    function getToken(address _tokenAddress) public view
        returns (
            uint256,
            bool
            )
    {   
        Token memory _token = token[_tokenAddress];
        return (
            _token.fee,
            _token.kindFee
        );
    }
}
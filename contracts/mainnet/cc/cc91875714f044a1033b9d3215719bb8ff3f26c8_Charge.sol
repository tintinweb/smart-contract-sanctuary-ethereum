/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: NONE

//    ____ _                                  
//   / ___| |__   __ _ _ __ __ _  ___  
//  | |   | '_ \ / _` | '__/ _` |/ _ \
//  | |___| | | | (_| | | | (_| |  __/
//   \____|_|_|_|\__,_|_|  \__, |\___|
//         _ __            |___/
//  __   _|___ \
//  \ \ / / __) |
//   \ V / / __/
//    \_/ |_____|
                
pragma solidity 0.8.10;

interface IERC721 {
	function ownerOf(uint256 _user) external view returns(address);
    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view virtual returns (string memory) {
        return _name;
    }

    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }
}

contract Charge is ERC20("ChargeV2", "ChargeV2"), ReentrancyGuard {
    uint256 constant private rewardtimeframe = 86400; 
	uint256 private FirstRedeemRate = 70 ether; 
	bool private isPauseEnabled;
    address private _owner;
    IERC20 chargeContract;
    mapping(address => uint) private rateForNFT;
    mapping(address => mapping(uint => uint)) private lastUpdateMap;

	constructor() {
		_owner = _msgSender();

        // Charge V1
        chargeContract = IERC20(0x0235a4Fa8374fd49BB2f01aC953f99748756f3Bd);
        // Charged Punks
        rateForNFT[0x14b98025B6e87c0B8F297F4456797D22cbDF99a8] = 10;
	}

    function payRateFrom(address nftContract) private view returns (uint) {
        unchecked {
            return rateForNFT[nftContract] * 1e18;
        }
    }

	function aGetRewards(uint256[] calldata _tokenIds, address nftContract) nonReentrant external {
        require(isPauseEnabled == false, "Staking is on pause");
        uint256 count =  _tokenIds.length;
		uint256 ramount = 0;
		uint256 tamount = 0;
        uint256 payRate = payRateFrom(nftContract);
        uint256 time = block.timestamp;

        require(payRate > 0, "This NFT cant generate CHARGE");

        unchecked {
            for(uint256 i = 0; i < count; i++) {
                uint punk = _tokenIds[i];
                require(msg.sender == IERC721(nftContract).ownerOf(punk), "You are not the owner of this punk");
                if(lastUpdateMap[nftContract][punk] == 0) {
                    ramount = FirstRedeemRate;
                } else {
                    ramount = uint(time - lastUpdateMap[nftContract][punk]) / rewardtimeframe * payRate;
                }
                
                if(ramount > 1){
                    lastUpdateMap[nftContract][punk] = time;
                    tamount += ramount;
                }
            }
        }
		require(tamount > 1, "Your punks didn't work hard enough");	
		_mint(msg.sender, tamount);
	}

	function aGetReward(uint256 _punk, address nftContract) nonReentrant external {
        require(isPauseEnabled == false, "Staking is on pause");
		require(msg.sender == IERC721(nftContract).ownerOf(_punk), "You are not the owner of this punk");

		uint256 ramount = 0;
        uint payRate = payRateFrom(nftContract);

        require(payRate > 0, "This NFT cant generate CHARGE");

		if(lastUpdateMap[nftContract][_punk] == 0) {
		    ramount = FirstRedeemRate;
		} else {
            unchecked {
                ramount = uint(block.timestamp - lastUpdateMap[nftContract][_punk]) / rewardtimeframe * payRate;
            }
        }

		require(ramount > 1, "Your punk didn't work hard enough");
		lastUpdateMap[nftContract][_punk] = block.timestamp;
		_mint(msg.sender, ramount);
	}

    function bResetStaking(uint[] calldata _tokenIds, address nftContract) external nonReentrant {
        unchecked {
            for (uint256 index = 0; index < _tokenIds.length; index++) {
                lastUpdateMap[nftContract][_tokenIds[index]] = block.timestamp;
            }
        }
    }

	function zSetPauseStatus(bool _isPauseEnabled) external {
	    require(_owner == _msgSender(), "Ownable: caller is not the owner");
        isPauseEnabled = _isPauseEnabled;
    }
	
	function zMint(uint256 coins) external {
	    require(_owner == _msgSender(), "Ownable: caller is not the owner");
	    coins = coins * 1 ether;
        _mint(msg.sender, coins);
	}
	
	function zAirdrop(address[] calldata _addresses, uint256 coins) external {
	    require(_owner == _msgSender(), "Ownable: caller is not the owner");
        if(coins < 1 ether) {
            coins = coins * 1 ether;
        }
        unchecked {
            for (uint256 ind = 0; ind < _addresses.length; ind++) {
                _mint(_addresses[ind], coins);
            }
        }
	}

	function zAirdropToTokens(uint256[] calldata _tokenIds, uint256 coins, address nftContract) external {
	    require(_owner == _msgSender(), "Ownable: caller is not the owner");
		coins = coins * 1 ether;
        if(coins < 1 ether) {
            coins = coins * 1 ether;
        }
        unchecked {
            for (uint256 ind = 0; ind < _tokenIds.length; ind++) {
                _mint(address(IERC721(nftContract).ownerOf(_tokenIds[ind])), coins);
            }
        }
    }

    function zSetFirstRedeemRate(uint256 _FirstRedeemRate) external {
        require(_FirstRedeemRate != 0, "Cant set a redeemRate of Zero for first");
	    require(_owner == _msgSender(), "Ownable: caller is not the owner");
		FirstRedeemRate = _FirstRedeemRate * 1e18;
    }

    function zUpdateRewardTime(uint256[] calldata _tokenIds, uint256 newTime, address nftContract) external {
	    require(_owner == _msgSender(), "Ownable: caller is not the owner");
		for (uint256 index = 0; index < _tokenIds.length; index++) {
            lastUpdateMap[nftContract][_tokenIds[index]] = newTime;
	    }
	}

    function zGenerationRate(uint[] calldata amounts, address[] calldata nftContracts) external {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        require(amounts.length == nftContracts.length, "Must have equal array size");

        for (uint256 index = 0; index < amounts.length; index++) {
            rateForNFT[nftContracts[index]] = amounts[index];
	    }
    }

    function zTradeYa(uint amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(chargeContract.allowance(msg.sender, address(this)) >= amount, "Not enough allowance");
        require(chargeContract.transferFrom(msg.sender, address(this), amount));

        _mint(msg.sender, amount);
    }

    function lastTimestamp(uint punkId, address nftContract) external view returns (uint) {
        return lastUpdateMap[nftContract][punkId];
    }

    function zCheckReward(uint256 _punk, address nftContract) external view returns (uint)  {
        require(isPauseEnabled == false, "Staking is on pause");
		uint256 ramount = 0;
        uint payRate = payRateFrom(nftContract);

        require(payRate > 0, "This NFT cant generate CHARGE");

		if(lastUpdateMap[nftContract][_punk] == 0) {
		    ramount = FirstRedeemRate;
		} else {
            unchecked {
                ramount = uint(block.timestamp - lastUpdateMap[nftContract][_punk]) / rewardtimeframe * payRate;
            }
        }
        return ramount;
	}

    function zCheckRewards(uint256[] calldata _punk, address nftContract) external view returns (uint)  {
        uint rAmount = 0;
        for (uint256 index = 0; index < _punk.length; index++) {
            rAmount += this.zCheckReward(_punk[index], nftContract);
	    }
        return rAmount;
    }

    function viewTime() external view returns (uint) {
        return block.timestamp;
    }
}
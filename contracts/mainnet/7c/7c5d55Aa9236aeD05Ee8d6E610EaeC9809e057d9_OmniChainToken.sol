// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";


import "./ILayerZeroUserApplicationConfig.sol";
import "./ILayerZeroReceiver.sol";
import "./ILayerZeroEndpoint.sol";
import "./NonBlockingReceiver.sol";

// deploy this contract to 2+ chains for testing.
//
// sendTokens() function works like this:
//  1. burn local tokens on the source chain
//  2. send a LayerZero message to the destination OmniChainToken contract on another chain
//  3. mint tokens on destination in lzReceive()
contract OmniChainToken is ERC20, NonblockingReceiver, ILayerZeroUserApplicationConfig {


    mapping(uint16 => bytes) public remotes;

	address public marketingWallet = payable(0x335b5b3bE5D0cDBcbdb1CBaBEA26a43Ec01f84e9);
	
	address private uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	//New Features
	mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => bool) private _isExcludedFromFees;
	mapping (address => bool) private bots;
	address[] public potentialBots;
	
	bool public tradingActive = false;
	
	uint256 private tradingBlock = 0;
	uint256 private sellFees = 14;
	uint256 private buyFees = 7;
	
	uint256 public maxTxAmount;
	uint256 public maxWallet;
	

	uint256 public fixedSupply = 1_000_000_000 * 10**18;
    // constructor mints tokens to the deployer
    constructor(string memory name_, string memory symbol_, address _layerZeroEndpoint) ERC20(name_, symbol_){
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        _mint(msg.sender, fixedSupply); // give the deployer initial supply
		
		maxTxAmount = fixedSupply * 1 / 100; //1% of supply
		maxWallet = fixedSupply * 1 / 100; //1% of supply
		
		
		excludeFromFees(owner(), true);
		excludeFromFees(address(this), true);
		excludeFromFees(marketingWallet, true);
    }
	
	function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        automatedMarketMakerPairs[pair] = value;
    }

	
	function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }
	
	function isBot(address bot) public view returns (bool) {
		return bots[bot];
	}
	
	function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }
	
	function setMarketingWallet(address newWallet) public onlyOwner {
		marketingWallet = newWallet;
		excludeFromFees(newWallet, true);
	}

	function setFees(uint256 _buyFees, uint256 _sellFees) public onlyOwner {
		require(_buyFees <= 25 && _sellFees <= 25, "Fees must be under 25%");
		
		sellFees = _sellFees;
		buyFees = _buyFees;
		
	}
	
	function blackListPotentialBots() external onlyOwner {
		setBots(potentialBots);
	}
	
	function enableTrading() external onlyOwner {
		tradingBlock = block.number;
		tradingActive = true;
	}


    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= fixedSupply / 1000, "Cannot set maxTxAmount lower than 0.1%");
        maxTxAmount = newNum;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (fixedSupply * 5 / 1000), "Cannot set maxWallet lower than 0.5%");
        maxWallet = newNum ;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
		require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
		require(!bots[from] && !bots[to]);

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
		if (
			from != owner() &&
			to != owner() &&
			to != address(0) &&
			to != address(0xdead)
		){
			if(!tradingActive){
				require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
			}
			
			if (automatedMarketMakerPairs[from] && !_isExcludedFromFees[to]) {
				require(amount <= maxTxAmount, "Buy transfer amount exceeds the maxTxAmount.");
			}
                
			//when sell
			else if (automatedMarketMakerPairs[to] && !_isExcludedFromFees[from]) {
				require(amount <= maxTxAmount, "Sell transfer amount exceeds the maxTxAmount.");
			}
			
			if (!automatedMarketMakerPairs[to] && !_isExcludedFromFees[from]) {
                require(balanceOf(to) + amount < maxWallet, "TOKEN: Balance exceeds wallet size!");
            }
			
			if (tradingActive && block.number <= tradingBlock + 2 && automatedMarketMakerPairs[from] && to != uniswapV2Router && to != address(this)) {  
                potentialBots.push(to);
            }
		 
		}
        

        bool takeFee = true;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // on sell
            if (automatedMarketMakerPairs[to] && sellFees > 0){
                fees = amount * sellFees / 100;
            }
            // on buy
            else if(automatedMarketMakerPairs[from] && buyFees > 0) {
        	    fees = amount * buyFees / 100;
            }
            
            if(fees > 0){    
                super._transfer(from, marketingWallet, fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }
	
	function manualSend() external onlyOwner {
		bool success;
		(success,) = address(marketingWallet).call{value: address(this).balance}("");
	}

    // send tokens to another chain.
    // this function sends the tokens from your address to the same address on the destination.
    function sendTokens(
        uint16 _chainId,                            // send tokens to this chainId
        bytes calldata _dstOmniChainTokenAddr,      // destination address of OmniChainToken
        uint _qty                                   // how many tokens to send
    )
        public
        payable
    {
        require(!bots[msg.sender]);
        // and burn the local tokens *poof*
        _burn(msg.sender, _qty);

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, _qty);

        // send LayerZero message
        endpoint.send{value:msg.value}(
            _chainId,                       // destination chainId
            _dstOmniChainTokenAddr,         // destination address of OmniChainToken
            payload,                        // abi.encode()'ed bytes
            payable(msg.sender),            // refund address (LayerZero will refund any superflous gas back to caller of send()
            address(0x0),                   // 'zroPaymentAddress' unused for this mock/example
            bytes("")                       // 'txParameters' unused for this mock/example
        );
    }


    // receive the bytes payload from the source chain via LayerZero
    // _fromAddress is the source OmniChainToken address
     function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal override {
        // decode
        (address toAddr, uint qty) = abi.decode(_payload, (address, uint));

        // mint the tokens back into existence, to the toAddr from the message payload
        _mint(toAddr, qty);
    }
	
	//---------------------------DAO CALL----------------------------------------
    // generic config for user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }
}
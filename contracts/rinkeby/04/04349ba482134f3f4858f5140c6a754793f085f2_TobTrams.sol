/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity ^0.8.9;

interface ISaleContract {
    function totalSold() external view returns (uint256);
    function merkleRoot() external view returns (bytes32);

    function buy(uint256 _amount, address _receiver, bytes32[] calldata _proof) external payable;
}

interface IBuyer {
    function buy() external payable;
}

contract TobTrams {
	// Não será necessário implementar IERC721Receiver, pois quem irá receber será uma conta EOA

    error InsufficientBalanceError();
    error InsufficientSupplyError();
    error PublicSaleNotInitializedError();
    
	address public owner;
	uint256 constant QTY_PER_TX = 2; // preço para comprar 2
    uint256 constant COST_PER_UNITY = 0.145 ether; // preço para comprar 2
    address constant SALE_CONTRACT_ADDRESS = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
    
	constructor() {
		owner = msg.sender;
	}

    function getBalance() external view returns(uint256 balance) {
        balance = address(this).balance;
    }

    function withdrawAll() external {
    	payable(owner).transfer(address(this).balance);
    }

    function buy(uint256 numberOfPurchases) external {
        // OBS.: para comprar, a grana já deve ter sido previamente enviada para o contrato

        if (this.getBalance() < (numberOfPurchases * QTY_PER_TX * COST_PER_UNITY)) {
            revert InsufficientBalanceError();
        }

    	bytes32 _merkleRoot = ISaleContract(SALE_CONTRACT_ADDRESS).merkleRoot();

    	if (_merkleRoot == bytes32(type(uint256).max)) { // PUBLIC SALE INICIADA!
    		uint256 _totalSold = ISaleContract(SALE_CONTRACT_ADDRESS).totalSold();
    		uint256 _available = 8425 - _totalSold; // [8425] é máximo que pode ser mintado pela função "buy"

    		if ((_available + 1) > (2*numberOfPurchases)) { // SUPPLY SUFICIENTE
    			for(uint256 i = 0; i < numberOfPurchases; i++) {
		            IBuyer buyer = new Buyer(); // instancia um novo contrato!
		        	buyer.buy{value:(QTY_PER_TX * COST_PER_UNITY)}(); // chama o "buy", enviando grana
		        }
    		} else {
                revert InsufficientSupplyError();
            }
    	} else {
            revert PublicSaleNotInitializedError();
        }
    } 

    fallback() external payable {
    }
}

contract Buyer is IBuyer {
	uint256   constant COST_PER_TX = 0.29 ether; // preço para comprar 2
	address   constant SALE_CONTRACT_ADDRESS = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
	address   constant RECEIVER_ADDRESS = 0x976EA74026E726554dB657fA54763abd0C3a0aa9; // DESTINATÁRIO DOS NFTS!
	uint256   constant AMOUNT = 2;
	bytes32[] PROOF;

    function buy() external payable {
        ISaleContract(SALE_CONTRACT_ADDRESS).buy{value:COST_PER_TX}(AMOUNT, RECEIVER_ADDRESS, PROOF);
    } 
}
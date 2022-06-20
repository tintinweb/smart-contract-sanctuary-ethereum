/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library Math {


    function percent(uint256 a, uint256 b) public pure returns(uint256){
        uint256 c = a - a*b/100;
        return c;
    }




}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowence(address owner, address spender) external view returns(uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);
}

contract CryptoToken is IERC20 {
    //Libs
    using Math for uint256;

    //Enums
    enum Status {
        ACTIVE,
        PAUSED,
        CANCELLED,
        KILLED
    }

    //Properties
    string public constant name = "CryptoToken";
    string public constant symbol = "CRY";
    uint8 public constant decimals = 3; //Default dos exemplos é sempre 18
    uint256 private totalsupply;
    uint256 private burnable;
    address private owner;
    address[] private tokenOwners;
    address private furnace;
    Status contractState;

    mapping(address => uint256) private addressToBalance;
    mapping(address => mapping(address => uint256)) allowed;

    modifier isOwner() {
        require(address(msg.sender) == owner, "Sender is not owner!");
        _;
    }

    //Constructor
    constructor() {
        uint256 total = 1000;
        totalsupply = total;
        owner = msg.sender;
        addressToBalance[owner] = totalsupply;
        tokenOwners.push(owner);
        contractState = Status.ACTIVE;
    }

    //Public Functions
    function totalSupply() public view override returns (uint256) {
        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        return totalsupply;
    }

    function balanceOf(address tokenOwner) public view override
        returns (uint256)
    {
        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        return addressToBalance[tokenOwner];
    }

    function burn(uint256 value) public isOwner returns (bool) {
        //require(contractState == Status.ACTIVE,"The Airdrop is not available now :(");
        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        furnace = 0xf000000000000000000000000000000000000000;

        for (uint256 i = 0; i < tokenOwners.length; i++) {
            addressToBalance[tokenOwners[i]] = addressToBalance[tokenOwners[i]]
                .percent(value);

            emit Transfer(
                tokenOwners[i],
                furnace,
                addressToBalance[tokenOwners[i]]
            );
        }
        totalsupply = totalsupply.percent(value);

        return true;
    }

    function autoBurn(uint256 value) public isOwner {
        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        burnable = value;
        burn(burnable);
    }

    function transfer(address receiver, uint256 quantity)
        public
        override
        isOwner
        returns (bool)
    {

        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        require(
            quantity <= addressToBalance[owner],
            "Insufficient Balance to Transfer"
        );
        addressToBalance[owner] = addressToBalance[owner] - quantity;
        addressToBalance[receiver] = addressToBalance[receiver] + quantity;
        tokenOwners.push(receiver);
        autoBurn(burnable);

        emit Transfer(owner, receiver, quantity);
        return true;
    }

    //Mint: Adicionar tokens ao total supply
    function mintToken() public isOwner {
        require(
            contractState == Status.ACTIVE,
            "The Contract is not available now :("
        );
        uint256 amount = 1000;
        if (balanceOf(owner) < 1001) {
            totalsupply += amount;
            addressToBalance[owner] += amount;
            emit Transfer(owner, owner, 1000);
        }
    }

    function approve(address spender, uint256 numTokens) public  isOwner override  returns(bool){
        allowed[msg.sender][spender] = numTokens;
        emit Approval(msg.sender, spender, numTokens);
        return true;
    }

    function allowence(address ownerToken, address spender) public override view returns(uint256){
        return allowed[ownerToken][spender];
    }

    function transferFrom(address from, address to, uint256 amount) public override  returns(bool){
        require(amount <= addressToBalance[from], "Sender Insufficient Balance to Transfer");
        require(amount <= allowed[from][msg.sender], "Allowed Insufficient Balance to Transfer");
        addressToBalance[from] -= amount;
        allowed[from][msg.sender] -= amount;
        addressToBalance[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function getOwner() public view returns(address){
        return address(owner);
    }
    
    function state() public view returns (Status) {
        return contractState;
    }

    function cancelContract() public isOwner  {
        contractState = Status.CANCELLED;
    }

    function pauseContract() public isOwner {
        contractState = Status.PAUSED;
    }

    function activeContract() public isOwner {
        contractState = Status.ACTIVE;
    }

    function kill() public isOwner {
        require(contractState == Status.CANCELLED, "The contract is active");
        contractState = Status.KILLED;
        selfdestruct(payable(owner));
    }
}
contract VendingMachine {

    // Properties
    address public owner2;
    mapping (address => uint) public GamaToBalances;
    uint256 private gamaBuyValue;
    uint256 private gamaSellValue;
    uint256 private ethBuyValue;
    uint256 private ethSellValue;
    uint256 private senderValue;
    address private tokenAddress;


    event Transfer(address from, address to, uint256 value);

    // Modifers
    modifier isOwner2(){
        require(msg.sender == owner2, "Only the onwer can make this");
        _;
    }

    //Constructor

    constructor(address contractAddress){
      
        owner2 = msg.sender;
        gamaBuyValue = 1;
        gamaSellValue = 1;
        ethBuyValue = 1;
        ethSellValue = 1;
        tokenAddress = contractAddress;
        //restockGama();
    }

    // Public Function

		//Função para Compra de Gama por ETH na máquina de venda.
    function purchaseGama(uint256 amount) public payable  {
        uint256 avaiableEther;
        avaiableEther = msg.value/1000000000000000000;
        require(avaiableEther*gamaBuyValue == amount,"Please quantity of ethers must be proportional to the price ratio");
        //um "if" pra indicar o valor mínimo de compra no caso é de 1 eth, já que no exemplo 1 eth = 1gama
        require(msg.value > 0 ,"Erro, not enough ethers to trade.");
        
				//um "if" pra saber se existe gama suficiente pra vender na máquina da venda.
        require(GamaToBalances[address(this)] >= amount, "Not enough Gamas in stock to fulfill purchase request.");
				//decremento do valor comprado em gama da máqunia
        GamaToBalances[address(this)] -= amount;
				//incremento do valor comprado para carteira do comprador
        GamaToBalances[msg.sender] += amount;
				//incremento do eth pago na transação para o saldo de ETH da máquina de venda
        emit Transfer(address(this), msg.sender, amount);
        
    }

	    function sellingGama(uint256 amount) public payable {
			//Aqui são os mesmo comentários do de compra só que pro de venda.
        //require(GamaToBalances[msg.sender] >= amount * 1 ether, "You must Sell at least 1 ether in Gama.");
        require(GamaToBalances[msg.sender] >= amount, "Not enough Gamas to trade for ether.");
        GamaToBalances[msg.sender] -= amount;
        GamaToBalances[address(this)] += amount;
				//essas duas ultimas linhas estão diferentes da função de cima por causa de 
        //um detalhe que percebi, se agente coloca apenas 
			  //"EthToBalances[address(this)] -= amount" eu estaria adicionado o valor em wei
        //então quando a carteira vendesse 1 gama = 1 eth a gente receberia 1 wei, 
				//por isso criei uma var weiToEther com o valor de 1 eth em wei ai 
				// só multiplicar o amount pela weiToEther que temos o valor em ETHER, 
        //deu pra sacar? 
        payable(msg.sender).transfer(weiToEther(amount)*gamaSellValue);
        emit Transfer(msg.sender, address(this), amount);
    }

    //Function weiToEther *Converte de wei para ether
    function weiToEther(uint256 amount) public pure returns(uint256 weiEther){
        weiEther = amount*1000000000000000000;
        return weiEther;
    }

    //Functions Getters and Setters

    function getVendingMachineBalanceGama() public view returns(uint256 GamaToken){
        return GamaToBalances[address(this)];

    }

    function getBuyerBalanceGama() public view returns(uint256 GamaToken){
        return GamaToBalances[address(owner2)];

    }

    function getVendingMachingBalanceEth() public view returns(uint256 EthToken){
        return address(this).balance;
    }


    function setGamaSellValue(uint256 newValue) public isOwner2{
        require(newValue > 0,"New value must be higher than 0.");
        gamaSellValue = newValue;

    }

    function setGamaBuyValue(uint256 newValue) public isOwner2{
        require(newValue > 0,"New value must be higher than 0.");
        gamaBuyValue = newValue;
    }

    //Funções de manutenção

    function restockGama() public isOwner2 {
          require(getVendingMachineBalanceGama() < 50,"You need to have less than 50 to restock.");
          uint256 amountGama = 1000;
          require(amountGama > 0,"You can't restock 0 or less Gamas.");
          
          CryptoToken(tokenAddress).transferFrom(owner2, address(this), amountGama);
          GamaToBalances[address(this)] += amountGama;
          /* CryptoToken(tokenAddress).mintToken(); */
    }

    function getOwner() public view returns(address){
        return address(owner2);
    }
  

    function restockEth() public payable isOwner2{
        require(msg.value >0,"You can't restock 0 or less Ethers.");
        
    }

    function contractBalance () public view returns(uint256) {
      return address(this).balance;
    }

    function ownerBalance() public view returns(uint256){
      return address(owner2).balance;
    }

    function toWithdraw(uint256 amountWithdraw) public payable isOwner2{
        require(amountWithdraw <= address(this).balance, "Not enough eth to withdraw.");
        payable(msg.sender).transfer(weiToEther(amountWithdraw));
        emit Transfer(address(this), msg.sender, amountWithdraw);
    }

    // Private Functions
    

    
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";


contract IAmEVE is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {

    // This sets the name and symbol of our NFT contract when it is created.
    constructor() ERC721A("I am EVE", "IAEVE") {}

    // Estas são as tralhas que vieram do contrato velho
    // Eu vou refazendo isso para ficar decente...

    /**
    Este é o limite inicial por carteira.
    Ele pode ser alterado usando "updatePublicMintStageLimitPerWallet"
    Este limite não se aplica aos itens do Drop.
     */
    uint public publicMintStageLimitPerWallet = 40;

    function updatePublicMintStageLimitPerWallet(uint128 _publicMintStageLimitPerWallet) external onlyOwner {
        publicMintStageLimitPerWallet = _publicMintStageLimitPerWallet;
    }

    /**
    Este é o preço inicial de cada item
    Ele pode ser alterado usando "updatePublicMintStagePrice "
    O preço será zero para os itens do Drop.
     */
    uint128 public publicMintStagePrice  = 0.0005 ether;

    function updatePublicMintStagePrice (uint128 _newPrice) external onlyOwner {
        publicMintStagePrice  = _newPrice;
    }
    
    /**
    Este é o máximo de itens disponível na coleção como um todo.
    Ele pode ser alterado através de "updateMaxMintsAvailable"
     */
    
    uint public MaxMintsAvailable = 100;

    function updateMaxMintsAvailable(uint64 _NewMaxMintsAvailable) external onlyOwner {
        MaxMintsAvailable = _NewMaxMintsAvailable;
    }
    
    /**
    Este é o flag indicativo de se o mint está publicamente disponível (true)
    Ele pode ser alterado em "setPublicMintStage"
    O drop não é afetado por esse flag.
     */

    bool public isPublicMintStageActive = false;

    function setPublicMintStage(bool newState) external onlyOwner returns (bool) {
        isPublicMintStageActive = newState;
        return isPublicMintStageActive;
    }

    /**
    Este é o endereço base do arquivo de metadados correspondente a cada um dos tokens
    Ele pode ser alterado em "setBaseURI"
     */

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
    Este é o tamanho máximo do lote por transação. O limite tem que ser necessáriamente menor que o limite por carteira.
    Ele pode ser alterado em setMaximumMintsPerTransaction
     */

    uint public maximumMintsPerTransaction = 30;

    function setMaximumMintsPerTransaction(uint _newMaximum) external onlyOwner {
        require(_newMaximum <= publicMintStageLimitPerWallet, "Maximum per Transaction must be equal or less than the Limit per Wallet");
        require(_newMaximum > 0, "Maximum Batch Size must be larger than zero");

        maximumMintsPerTransaction = _newMaximum;
    }

    /**
    Cunhagem em lote (implícita ao requisitante)
     */

    function batchMint(uint _batchSize) external payable {
        publicMintValidation(msg.sender, _batchSize);

        // Todos os requisitos satisfeitos, cunhar.
        _mint(msg.sender,_batchSize);
    }

    /**
    Cunhagem a terceiros.
     */
    function mintTo(address _mintToAddress, uint128 _batchSize) external payable
    {
        publicMintValidation(_mintToAddress, _batchSize);

        // Todos os requisitor satisfeitos, cunhar.
        _mint(_mintToAddress,_batchSize);
    }

    /**
    Validações comuns aos processos de cunhagem públicos
     */
    function publicMintValidation(address toAddress, uint _batchSize) internal {
        // Suprimento está disponível?
        require((totalSupply() + _batchSize) <= MaxMintsAvailable, "Not enough Tokens left");

        // Menor lote possível é 1
        require(_batchSize > 0, "Batch Size must be at least One");

        // Maior lote possível é o da configuração
        require(_batchSize <= maximumMintsPerTransaction, "Maximum Batch Size per Transaction is exceeded.");

        // Mintagem deve estar aberta
        require(isPublicMintStageActive, "Public Mint not active");

        // Carteira não pode já conter mais tokens que o máximo permitido
        require(
            (balanceOf(toAddress) + _batchSize) <= publicMintStageLimitPerWallet,
            "Batch Size may not exceed limit for this Address"
        );

        // Valor pago deve ser suficiente para todos os tokens!
        uint256 batchPrice = publicMintStagePrice  * _batchSize;

        require(
            msg.value == batchPrice,
            "Incorrect Price for the Batch"
        );

        return;
    }

    /**
    Cunhagem especial para o dono do contrato custa apenas a taxa de Gas
    Pode ser usada para fazer um drop "caro" de novos tokens
     */
    function batchOwnerMintTo(address toAddress, uint _batchSize) external onlyOwner {
        // A única validação que existe neste caso é se existem tokens disponíveis
        // Suprimento está disponível?
        require((totalSupply() + _batchSize) <= MaxMintsAvailable, "Not enough Tokens left");

        _mint(toAddress, _batchSize);
    }

    /**
    Saque de fundos do contrato para uma carteira específica.
     */

    function withdrawContract(address payable _to, uint256 _amount) public nonReentrant onlyOwner
    {
        (bool sent, bytes memory data) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }


    // --- Whitelist --- //

    whiteListData[] private whitelistedMints;
    uint256 private whitelistSize;

    /**
    Adiciona ou atualiza um endereço específico autorizado ao mint/claim com a respectiva quantidade.
     */
    function addAddressToMintWhitelist(address _whitelistedAddress, uint256 _whitelistedAmount) public onlyOwner {

        bool wasFound = false;

        for (uint256 i = 0; i < whitelistSize; i++)
        {
            if (whitelistedMints[i].mintAddress == _whitelistedAddress)
            {
                whitelistedMints[i].amount += _whitelistedAmount;
                wasFound = true;
                break;
            }
        }

        if (!wasFound)
        {
            whiteListData memory w;
            w.mintAddress = _whitelistedAddress;
            w.amount = _whitelistedAmount;

            whitelistedMints.push(w);
            whitelistSize++;
        }
    }

    /**
    Atualiza a lista toda de endereços autorizados e suas respectivas quantidades de uma vez só. Economiza gas?
     */
    function updateDropClaimList(whiteListData[] calldata _whitelistedMints) public onlyOwner {
        // Deveria ser simples, não é.
        // whitelistedMints = _whitelistedMints;

        // Então não simples.
        delete whitelistedMints;

        for (uint256 i = 0; i < _whitelistedMints.length; i++)
        {
            // Como a lista foi deletada, itens com contagem zero não devem ser adicionados para economizar gas.
            if (_whitelistedMints[i].amount > 0)
            {
                whiteListData memory d;
                d = _whitelistedMints[i];

                whitelistedMints.push(d);
            }
        }
        
        // Importante, é o tamanho da lista final e não o da lista originalmente fornecida.
        whitelistSize = whitelistedMints.length;
    }

    /**
    Obtém a quantidade de mints/claims remanescentes para um endereço.
    Qualquer endereço não autorizado vai retornar o valor zero.
     */
    function whitelistedAmount(address _whitelistedAddress) public view returns (uint256)
    {
        for (uint256 i = 0; i < whitelistSize; i++)
        {
            if (whitelistedMints[i].mintAddress == _whitelistedAddress)
            {
                return whitelistedMints[i].amount;
            }
        }

        return 0;
    }

    // Não há uma forma eficiente de obter a lista toda...
    // Então temos uma ineficiente.
    function getWhitelist() external view returns (whiteListData[] memory) {
        return whitelistedMints;
    }

    /**
    É assim que espero receber a Whitelist, seja para mintagem em lote ou para checar se está na lista de autorização para claim
     */
    struct whiteListData {
        address mintAddress;
        uint256 amount;
    }

    // --- Claim a partir da Whitelist --- //
    // Este processo envolve o usuário acionando uma função específica e pagando o gas correspondente (mas não o mint em si)
    // Notar que qualquer um pode invocar essa função, mas o destino do token sempre é o endereço informado (que está na whitelist)
    // e nunca o do invocador da função. Ou seja, algum agente externo pode simplesmente mintar para um terceiro mas nunca poderia
    // roubar um token.
    function claimFromWhitelist(address _address, uint256 _number) public {
        uint256 availableAmount = 0;
        bool wasFound = false;

        // Requerido que o claim seja de um ou mais tokens
        require(_number > 0, "Wouldn't you want to claim at least one token?");
        
        // Pode ser zero!
        uint256 foundIndex;

        for (uint256 i = 0; i < whitelistSize; i++)
        {
            if (whitelistedMints[i].mintAddress == _address)
            {
                availableAmount = whitelistedMints[i].amount;
                wasFound = true;
                foundIndex = i;
                break;
            }
        }

        // O endereço está na Whitelist?
        require(wasFound, "Address is not on the Claim whitelist.");

        // O endereço tem saldo suficiente?
        require(availableAmount >= _number, "Address may not Claim more than the whitelisted quantity.");

        // Há tokens cunháveis suficientes?
        require((totalSupply() + _number) <= MaxMintsAvailable, "Not enough Tokens left");

        // Passou todos os testes
        // Cunhar
        _mint(_address, _number);

        // Decrementar o saldo
        whitelistedMints[foundIndex].amount -= _number;
    }

    // --- Mintagem a partir da Whitelist inteira --- //
    // Este processo envolve o dono do contrato disparando um evento que vai mintar cada um dos itens do Whitelist para dentro de cada
    // um dos membros ali presentes.
    // Provavelmente custa um bocado de gas.

    function mintWhiteList() public onlyOwner {
        // Checar se a soma dos saldos é inferior ou igual a todos os mints que precisam ser feitos.
        uint256 totalToBeMinted = totalMintsWhiteList();

        require((totalSupply() + totalToBeMinted) <= MaxMintsAvailable, "Not enough Tokens left for the whole whitelist.");

        // Passou todos os testes, mintar
        for (uint256 i = 0; i < whitelistSize; i++)
        {
            // É possível que um item tenha feito o Claim antes e zerado a quota,
            // Ou que um admin tenha zerado manualmente via adição manual do valor zero.
            if (whitelistedMints[i].amount > 0)
            {
                _mint(whitelistedMints[i].mintAddress, whitelistedMints[i].amount);
            }
        }

        // Depois disso, ninguém mais está na whitelist.
        delete whitelistedMints;

        // Não esquecer disso, se não quiser que a EVM surte.
        whitelistSize = 0;
    }

    function totalMintsWhiteList() public view returns (uint256) {
        uint256 totalToBeMinted = 0;

        for (uint256 i = 0; i < whitelistSize; i++)
        {
            totalToBeMinted+= whitelistedMints[i].amount;
        }

        return totalToBeMinted;
    }
}
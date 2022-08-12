// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: zeclion
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                             //
//                                                                                                                             //
//    Purchase Agreement of NFT                                                                                                //
//    This Purchase Agreement of NFT ("Agreement") between you and the                                                         //
//    Platform governs your participating in purchase NFT (as defined                                                          //
//    below) on the Platform.                                                                                                  //
//    THE PLATFORM IS NOT A BROKER, FINANCIAL INSTITUTION, OR                                                                  //
//    CREDITOR. THE SERVICES ARE ADMINISTRATIVE ONLY. YOU BEAR                                                                 //
//    FULL RESPONSIBILITY FOR VERIFYING THE IDENTITY, LEGITIMACY,                                                              //
//    AND AUTHENTICITY OF NFT YOU PURCHASED ON THE PLANTFORM.                                                                  //
//    NOTWITHSTANDING INDICATORS AND MESSAGES THAT SUGGEST                                                                     //
//    VERIFICATION, THE PLANTFORM MAKES NO CLAIMS ABOUT THE                                                                    //
//    IDENTITY, LEGITIMACY, OR AUTHENTICITY OF NFT ON THE                                                                      //
//    PLATFORM.                                                                                                                //
//    In this Agreement, "you" and "your" refers to you, the purchaser of                                                      //
//    the crypto assets; “we”, “our” and ”us” refer to the trading platform                                                    //
//    or the site, the service provider (the “Platform”).                                                                      //
//    Description of the Services                                                                                              //
//    NFT refers to unique non-fungible tokens, which represent pieces of                                                      //
//    programmable arts in the form of non-fungible ERC721 digital assets                                                      //
//    that themselves may be created by reference to a smart contract on                                                       //
//    the Ethereum blockchain. The Platform is an online trading platform                                                      //
//    where users can sell, purchase, list for auction, make offers, and bid                                                   //
//    on NFT. You can obtain NFT by making an offer accepted by the seller,                                                    //
//    purchasing at a list price, or bidding on NFT available in smart                                                         //
//    contract-enabled auctions. You will be able to search, browse, click                                                     //
//    on links, and purchase NFT that represent the digital Artworks on                                                        //
//    Platform. A purchaser that becomes an owner of Artwork (“Collector”)                                                     //
//    will have no intellectual property rights to that Artwork.                                                               //
//    Ownership                                                                                                                //
//    Owning a NFT is similar to owning a piece of physical art. You own a                                                     //
//    cryptographic token representing the Artist’s creative Artwork as a                                                      //
//    piece of property, but you do not own the creative Artwork itself.                                                       //
//    Collectors may show off their ownership of collected NFT by                                                              //
//    displaying and sharing the Underlying Artwork, but Collectors do not                                                     //
//    have any legal ownership, right, or title to any copyrights, trademarks,                                                 //
//    or other intellectual property rights to the underlying Artwork,                                                         //
//    excepting the limited license granted by these Terms to underlying                                                       //
//    Artwork. The Artist reserves all exclusive copyrights to Artworks                                                        //
//    underlying NFT on the Platform, including but not limited to the right                                                   //
//    to reproduce, to prepare derivative works, to display, to perform, and                                                   //
//    to distribute the Artworks. The Collectors may not infringe on any of                                                    //
//    the exclusive rights of the copyright the Artist.                                                                        //
//    Purchasing NFT with a List Price                                                                                         //
//    NFT is optionally offered for immediate acceptance at a List Price                                                       //
//    established by the seller on Platform. You can purchase NFT with a                                                       //
//    List Price through Platform by sending an equivalent amount of                                                           //
//    cryptocurrency to a Smart Contract configured to initiate a transfer                                                     //
//    of the NFT, plus additional fees and gas.                                                                                //
//    Making Offers on NFT                                                                                                     //
//    You can make offers on all listed NFT through Platform. Offers on                                                        //
//    Platform are legally binding, revocable offers to purchase the NFT                                                       //
//    capable of immediate acceptance by the seller of the NFT. By making                                                      //
//    an offer, you agree to temporarily send and lose control over an                                                         //
//    amount of offered cryptocurrency to a Smart Contract. The Smart                                                          //
//    Contract is configured to hold the offered cryptocurrency until either                                                   //
//    the offer is accepted by the seller, a higher offer is received, or the                                                  //
//    offer is revoked. The seller of the NFT has the unilateral authority to                                                  //
//    accept the bid.                                                                                                          //
//    Fees                                                                                                                     //
//    Every transaction on Platform is subject to Fees collected to support                                                    //
//    the Platform. You authorize Platform as applicable, to initiate debits                                                   //
//    in your account in settlement of transactions. You agree to pay                                                          //
//    Platform any transaction fees for purchase of NFT and authorize                                                          //
//    Platform to deduct such fees from your account directly.                                                                 //
//    You agree and understand that all fees, commissions, and royalties                                                       //
//    are transferred, processed, or initiated directly through one or more                                                    //
//    of the Smart Contracts on the Ethereum blockchain network. By                                                            //
//    transacting on the Platform and by using the Smart Contracts, you                                                        //
//    hereby acknowledge, consent to, and accept all automated fees,                                                           //
//    commissions, and royalties for the sale of NFT on the Platform. You                                                      //
//    hereby consent to and agree to be bound by the Smart Contracts’                                                          //
//    execution and distribution of the fees, commissions, and royalties.                                                      //
//    You hereby waive any entitlement to royalties, commissions, or fees                                                      //
//    paid to another by operation of the Smart Contracts.                                                                     //
//    Gas                                                                                                                      //
//    All transactions on the Platform, including without limitation bidding,                                                  //
//    listing, offering, purchasing, or confirming, are facilitated by Smart                                                   //
//    Contracts existing on the Ethereum network. The Ethereum network                                                         //
//    requires the payment of a transaction fee (a “Gas fee”) for every                                                        //
//    transaction that occurs on the Ethereum network, and thus every                                                          //
//    transaction occurring on Platform. The value of the Gas Fee changes,                                                     //
//    often unpredictably, and is entirely outside of the control of Platform.                                                 //
//    You acknowledges that under no circumstances will a contract,                                                            //
//    agreement, offer, sale, bid, or other transaction on Platform be                                                         //
//    invalidated, revocable, retractable, or otherwise unenforceable on the                                                   //
//    basis that the Gas Fee for the given transaction was unknown, too                                                        //
//    high, or otherwise unacceptable to you. You also acknowledge and                                                         //
//    agree that gas is non-refundable under all circumstances.                                                                //
//    No Representations or Warranties                                                                                         //
//    Digital artworks and its descriptions are posted for informational                                                       //
//    purposes only and may not be independently verified by Platfrom                                                          //
//    and/or its partners. Therefore, your reliance on such information is                                                     //
//    at your own risk. You should always verify information on the Platform                                                   //
//    before making a bid or purchase. Because we do not control User                                                          //
//    Content and/or other third-party sites and resources, you                                                                //
//    acknowledge and agree that we are not responsible for the accuracy                                                       //
//    or availability of any User Content and materials and/or external sites                                                  //
//    or resources. We make no guarantees regarding the accuracy,                                                              //
//    currency, suitability, or quality of any User Content. Your interactions                                                 //
//    with other Site users are solely between you and such users. You                                                         //
//    agree that Platform will not be responsible for any loss or damage                                                       //
//    incurred as the result of any such interactions. If there is a dispute                                                   //
//    between you and any Site user, Platform is under no obligation to                                                        //
//    become involved.                                                                                                         //
//    You acknowledge and consent to the risk that the price of NFT                                                            //
//    purchased on the Platform may have been influenced by user activity                                                      //
//    outside of the control of the Platform. The Platform does not                                                            //
//    represent, guarantee, or warrant the accuracy or fairness of the price                                                   //
//    of any NFT sold or offered for sale on the Platform. You agree and                                                       //
//    acknowledge that the Platform is not a fiduciary nor owes any duties                                                     //
//    to any user of the Platform, including the duty to ensure fair pricing                                                   //
//    of NFT or to influence user behavior on the Platform.                                                                    //
//    Transactions that take place on Platform are managed and confirmed                                                       //
//    via the Ethereum blockchain. You understand that your Ethereum                                                           //
//    public address will be made publicly visible whenever you engage in                                                      //
//    a transaction on Platform. We neither own nor control Google Chrome,                                                     //
//    the Ethereum network, or any other third party site, product, or                                                         //
//    service that you might access, visit, or use for the purpose of enabling                                                 //
//    you to use the various features of the Platform. We will not be liable                                                   //
//    for the acts or omissions of any such third parties, nor will we be                                                      //
//    liable for any damage that you may suffer as a result of your                                                            //
//    transactions or any other interaction with any such third parties.                                                       //
//    Platform facilitates transactions between the purchaser and seller of                                                    //
//    NFT. Platform is not the custodian of any NFT. You affirm that you are                                                   //
//    aware and acknowledge that Platform is a non-custodial service                                                           //
//    provider and has no responsibility to custody the NFT you purchased.                                                     //
//    Assumption of Risk                                                                                                       //
//    Participating in the purchase of NFT involves significant risks and                                                      //
//    potential financial losses, including but not limited to the following,                                                  //
//    you accept and acknowledge:                                                                                              //
//     You hereby acknowledge and assume the risk of initiating,                                                              //
//    interacting with, participating in transactions and take full                                                            //
//    responsibility and liability for the outcome of any transaction they                                                     //
//    initiate. Users hereby represent that they are knowledgeable,                                                            //
//    experienced and sophisticated in using blockchain technology, the                                                        //
//    Platform, and in initiating Ethereum-based transactions.                                                                 //
//     There are risks associated with purchasing user generated content,                                                     //
//    including but not limited to, the risk of purchasing counterfeit                                                         //
//    assets, mislabeled assets, assets that are vulnerable to metadata                                                        //
//    decay, assets on smart contracts with bugs, and assets that may                                                          //
//    become untransferable. The Platform assumes no liability or                                                              //
//    responsibility to you for any losses in transactions.                                                                    //
//     The Platform does not store, send or receive NFT. The NFT is                                                           //
//    transferred on the Smart Contract maintained by the Platform. Any                                                        //
//    transfers of NFT occur via the Smart Contract located on the                                                             //
//    Ethereum blockchain and not on Platform. Further, as NFTs are                                                            //
//    non-fungible, they are unrecoverable once damaged or lost. You                                                           //
//    confirm that you will transfer the NFTs out of the Platform for                                                          //
//    custody once after the completion of purchasing, and that Platform                                                       //
//    will not be responsible or liable to you for any loss in case the NFTs                                                   //
//    are damaged or lost.                                                                                                     //
//     There are risks associated with purchasing blockchain based                                                            //
//    tokens, including but not limited to, the risk of losing private keys,                                                   //
//    theft of cryptocurrency or tokens due to hackers finding out your                                                        //
//    private key, lack of a secondary market, significant price volatility,                                                   //
//    hard forks and disruptions to the Ethereum blockchain. You accept                                                        //
//    and acknowledge that transfers on the Ethereum blockchain are                                                            //
//    irreversible and as a result, it is not possible for the Platform to                                                     //
//    issue refunds on NFT purchases.                                                                                          //
//     Platform is not responsible for losses due to blockchains or any                                                       //
//    other features of the ethereum network or any ethereumcompatible browser or wallet, including but not limited to late    //
//    report by developers or representatives (or no report at all) of any                                                     //
//    issues with the blockchain supporting the ethereum network,                                                              //
//    including forks, technical node issues, or any other issues having                                                       //
//    fund losses as a result.                                                                                                 //
//     You acknowledge and agree that the smart contracts may be                                                              //
//    subject to bugs, malfunctions, timing errors, hacking and theft, or                                                      //
//    changes to the protocol rules of the Ethereum blockchain, which                                                          //
//    can adversely affect the smart contracts and may expose you to a                                                         //
//    risk of total loss, forfeiture of your digital currency or NFT, or lost                                                  //
//    opportunities to buy or sell NFT. The Platform assumes no liability                                                      //
//    or responsibility for any such smart contract or related failures,                                                       //
//    risks, or uncertainties.                                                                                                 //
//     You acknowledge that Platform is subject to flaws and                                                                  //
//    acknowledge that you are solely responsible for evaluating any                                                           //
//    code provided by the Platform. This warning and others provided                                                          //
//    in this Agreement by Platform in no way evidence or represent an                                                         //
//    ongoing duty to alert you to all of the potential risks of utilizing or                                                  //
//    accessing the Platform.                                                                                                  //
//     You are solely responsible for determining what, if any, taxes apply                                                   //
//    to your purchases and sales of NFT. The Platform is not responsible                                                      //
//    for determining the taxes that apply to NFT transactions.                                                                //
//    Representations and Warranties                                                                                           //
//    Before you purchase any NFT, you hereby represent and warrant that:                                                      //
//     You are an eligible purchaser of the asset and have read and                                                           //
//    understood all the terms of this Agreement and User Agreement                                                            //
//    of the Platform and fully understand all the risks herein and are                                                        //
//    willing to assume all the liabilities and losses.                                                                        //
//     You have sufficient understanding of the transaction and the NFT                                                       //
//    and make informed decision after performing your own due                                                                 //
//    diligence.                                                                                                               //
//     By purchasing any NFT, you are certifying to the Platform that the                                                     //
//    activities in connection with the purchase will comply with this                                                         //
//    Agreement and all applicable laws, rules and regulations. The NFT                                                        //
//    you receive will not be used in any forms of illegal activity,                                                           //
//    including but not limited to participating in or supporting any                                                          //
//    illegal activities.                                                                                                      //
//    No Liability                                                                                                             //
//    To the maximum extent permitted by law, in no event shall Platform                                                       //
//    be liable to you or any third party for any lost profits, lost data, or                                                  //
//    any indirect, consequential, exemplary, incidental, special or punitive                                                  //
//    damages arising from or relating to these terms or your use of, or                                                       //
//    inability to use, the site, even if Platform has been advised of the                                                     //
//    possibility of such damages. Access to, and use of, the site is at your                                                  //
//    own discretion and risk, and you will be solely responsible for any                                                      //
//    damage to your device or computer system, or loss of data resulting                                                      //
//    therefrom.                                                                                                               //
//    Indemnification                                                                                                          //
//    You agree to indemnify and hold harmless the Platform and its                                                            //
//    affiliates from and against any and all claims, costs, proceedings,                                                      //
//    demands, losses, damages, and expenses (including, without                                                               //
//    limitation, reasonable attorney’s fees and legal costs) of any kind or                                                   //
//    nature, arising from or relating to, any actual or alleged breach of the                                                 //
//    Agreement by you, a co-conspirator, or anyone using your account.                                                        //
//    If we assume the defense of such a matter, you will reasonably                                                           //
//    cooperate with us in such defense.                                                                                       //
//    Entire Terms.                                                                                                            //
//    This Agreement along with User Agreement on the Platform                                                                 //
//    constitute the entire agreement between you and us relating to your                                                      //
//    access to and use of the Services and Content, and your participation                                                    //
//    in the Transaction.                                                                                                      //
//    Updates to Terms and Conditions                                                                                          //
//    The Platform reserves the right to update, change or modify the                                                          //
//    terms of Agreement at any time and in our sole discretion. If we make                                                    //
//    changes to the terms, we will provide notice of such changes. If you                                                     //
//    do not agree to the revised Agreement, you may not access or use                                                         //
//    the Services.                                                                                                            //
//                                                                                                                             //
//                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BTCN is ERC721Creator {
    constructor() ERC721Creator("zeclion", "BTCN") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}
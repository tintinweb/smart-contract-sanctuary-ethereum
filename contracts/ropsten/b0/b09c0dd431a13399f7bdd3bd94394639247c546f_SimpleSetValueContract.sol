/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

/*
Generated by Jthereum BETA version!
┌──────────────┬──────────────────────────────┐
│     Atribute │                        Value │
├──────────────┼──────────────────────────────┤
│      Version │           2.1.3.406.release1 │
│         Beta │                         true │
│ Build Number │                          406 │
│   Build Date │ Fri Jul 22 09:31:58 EDT 2022 │
│   Short Hash │                 f7bffe58df30 │
│ Installation │ 0x213177e39c8cd4e5851cc2a698 │
└──────────────┴──────────────────────────────┘

*/
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

contract SimpleSetValueContract
{
	int32 private value;
	function setValue(int32 newValue) public 
	{
		value = newValue;
	}
	function getValue() public view returns (int32) 
	{
		return value;
	}

}

/*
 * Below is the original Java source used as input to Jthereum.
 * To regenerate the exact Java source files, remove all below single line
 * comments that start at column zero, and place the source in the indicated file.
 */

/*
 * Source for class testo.SimpleSetValueContract
 * File Path: ./src/testo/SimpleSetValueContract.java
 */

// package testo;
// 
// import com.u7.jthereum.*;
// import com.u7.jthereum.annotations.*;
// 
// import static com.u7.jthereum.Jthereum.*;
// 
// public class SimpleSetValueContract implements ContractProxyHelper
// {
// 	private int value;
// 
// 	public void setValue(final int newValue)
// 	{
// 		value = newValue;
// 	}
// 
// 	@View
// 	public int getValue()
// 	{
// 		return value;
// 	}
// 
// 	public static void main(final String[] args)
// 	{
// //		compile();
// 		compileAndDeploy("ropsten");
// //		compileAndDeploy("ropsten");
// 
// 		// Get the proxy for the deployed contract
// 		final SimpleSetValueContract a = createProxy(SimpleSetValueContract.class);
// 
// 		a.setValue(7);
// 
// 		final int value = a.getValue();
// 
// 		p("Got value: " + value);
// //*/
// 	}
// }
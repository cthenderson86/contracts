// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { SimpleERC20Paymaster, IEntryPoint } from "contracts/prebuilts/account/paymaster/SimpleERC20Paymaster.sol";
import "../utils/BaseTest.sol";

contract SimpleERC20PaymasterTest is BaseTest {
    SimpleERC20Paymaster private paymaster;
    IEntryPoint private entryPoint;

    uint256 private accountAdminPKey = 100;
    address private accountAdmin;

    uint256 private accountSignerPKey = 200;
    address private accountSigner;

    function setUp() public override {
        super.setUp();

        vm.startPrank(deployer);

        accountAdmin = vm.addr(accountAdminPKey);
        vm.deal(accountAdmin, 100 ether);
        accountSigner = vm.addr(accountSignerPKey);

        entryPoint = IEntryPoint(payable(address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789)));

        uint256 tokensPerOp = 1e18; // 1 token per op
        paymaster = new SimpleERC20Paymaster(entryPoint, erc20, tokensPerOp);

        vm.label(address(entryPoint), "EntryPoint");
        vm.label(address(paymaster), "Paymaster");
        vm.label(address(erc20), "Token");

        vm.stopPrank();
    }

    function test_postDeploy() public {
        address currentToken = address(paymaster.token());
        uint256 currentTokenPricePerOp = paymaster.tokenPricePerOp();
        address owner = paymaster.owner();

        assertEq(currentToken, address(erc20));
        assertEq(currentTokenPricePerOp, 1e18);
        assertEq(owner, deployer);
    }

    function test_updateTokenPrice() public {
        vm.startPrank(deployer);

        paymaster.setTokenPricePerOp(2e18);
        uint256 currentTokenPricePerOp = paymaster.tokenPricePerOp();

        assertEq(currentTokenPricePerOp, 2e18);

        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.startPrank(deployer);

        assertEq(erc20.balanceOf(address(paymaster)), 0);
        assertEq(erc20.balanceOf(deployer), 0);

        erc20.mint(address(paymaster), 1e18);

        assertEq(erc20.balanceOf(address(paymaster)), 1e18);
        assertEq(erc20.balanceOf(deployer), 0);

        paymaster.withdrawToken(deployer, 1e18);

        assertEq(erc20.balanceOf(address(paymaster)), 0);
        assertEq(erc20.balanceOf(deployer), 1e18);

        vm.stopPrank();
    }
}

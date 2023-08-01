// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "test/forge/BlueBase.t.sol";

contract IntegrationRepayTest is BlueBaseTest {
    function testRepayUnknownMarket(Market memory marketFuzz) public {
        vm.assume(neq(marketFuzz, market));

        vm.expectRevert(bytes(Errors.MARKET_NOT_CREATED));
        blue.repay(marketFuzz, 1, address(this), hex"");
    }

    function testRepayZeroAmount() public {
        vm.expectRevert(bytes(Errors.ZERO_AMOUNT));
        blue.repay(market, 0, address(this), hex"");
    }

    function testRepay(uint256 amountLent, uint256 amountBorrowed, uint256 amountRepaid) public {
        amountLent = bound(amountLent, 1, 2 ** 64);
        amountBorrowed = bound(amountBorrowed, 1, amountLent);
        amountRepaid = bound(amountRepaid, 1, amountBorrowed);

        borrowableAsset.setBalance(address(this), amountLent);
        blue.supply(market, amountLent, address(this), hex"");

        vm.startPrank(BORROWER);
        blue.borrow(market, amountBorrowed, BORROWER, BORROWER);
        blue.repay(market, amountRepaid, BORROWER, hex"");
        vm.stopPrank();

        assertEq(blue.totalBorrow(id), amountBorrowed - amountRepaid, "total borrow");
        assertApproxEqAbs(
            blue.borrowShare(id, BORROWER),
            (amountBorrowed - amountRepaid) * SharesMath.VIRTUAL_SHARES,
            100,
            "borrow share"
        );
        assertEq(borrowableAsset.balanceOf(BORROWER), amountBorrowed - amountRepaid, "BORROWER balance");
        assertEq(borrowableAsset.balanceOf(address(blue)), amountLent - amountBorrowed + amountRepaid, "blue balance");
    }

    function testRepayOnBehalf(uint256 amountLent, uint256 amountBorrowed, uint256 amountRepaid) public {
        amountLent = bound(amountLent, 1, 2 ** 64);
        amountBorrowed = bound(amountBorrowed, 1, amountLent);
        amountRepaid = bound(amountRepaid, 1, amountBorrowed);

        borrowableAsset.setBalance(address(this), amountLent + amountRepaid);
        blue.supply(market, amountLent, address(this), hex"");

        vm.prank(BORROWER);
        blue.borrow(market, amountBorrowed, BORROWER, BORROWER);
        blue.repay(market, amountRepaid, BORROWER, hex"");

        assertEq(blue.totalBorrow(id), amountBorrowed - amountRepaid, "total borrow");
        assertApproxEqAbs(
            blue.borrowShare(id, BORROWER),
            (amountBorrowed - amountRepaid) * SharesMath.VIRTUAL_SHARES,
            100,
            "borrow share"
        );
        assertEq(borrowableAsset.balanceOf(BORROWER), amountBorrowed, "BORROWER balance");
        assertEq(borrowableAsset.balanceOf(address(blue)), amountLent - amountBorrowed + amountRepaid, "blue balance");
    }
}

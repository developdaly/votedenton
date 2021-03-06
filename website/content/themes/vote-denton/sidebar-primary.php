<?php
/**
 * Primary Sidebar Template
 *
 * Displays widgets for the Primary dynamic sidebar if any have been added to the sidebar through the 
 * widgets screen in the admin by the user.  Otherwise, nothing is displayed.
 *
 * @package Vote Denton
 * @subpackage Template
 */

if ( is_active_sidebar( 'primary' ) ) : ?>

	<?php do_atomic( 'before_sidebar_primary' ); // vote_denton_before_sidebar_primary ?>

	<div id="sidebar-primary" class="sidebar <?php echo vote_denton_get_layout( 'sidebar' ); ?>">

		<?php do_atomic( 'open_sidebar_primary' ); // vote_denton_open_sidebar_primary ?>

		<?php dynamic_sidebar( 'primary' ); ?>

		<?php do_atomic( 'close_sidebar_primary' ); // vote_denton_close_sidebar_primary ?>

	</div><!-- #sidebar-primary .aside -->

	<?php do_atomic( 'after_sidebar_primary' ); // vote_denton_after_sidebar_primary ?>

<?php endif; ?>
package org.cftoolsuite.cfapp.support.console;

import java.net.URI;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.security.web.server.authentication.RedirectServerAuthenticationSuccessHandler;
import org.springframework.security.web.server.authentication.ServerAuthenticationSuccessHandler;
import org.springframework.security.web.server.authentication.logout.RedirectServerLogoutSuccessHandler;
import org.springframework.security.web.server.authentication.logout.ServerLogoutSuccessHandler;

import de.codecentric.boot.admin.server.config.AdminServerProperties;
import de.codecentric.boot.admin.server.config.EnableAdminServer;
import de.codecentric.boot.admin.server.notify.Notifier;
import reactor.core.publisher.Mono;

@Configuration(proxyBeanMethods = false)
@EnableAutoConfiguration
@EnableAdminServer
@EnableDiscoveryClient
public class App {

	private final AdminServerProperties adminServer;

	public App(AdminServerProperties adminServer) {
		this.adminServer = adminServer;
	}

	@Bean
	@Profile("insecure")
	public SecurityWebFilterChain securityWebFilterChainPermitAll(ServerHttpSecurity http) {
		return http.authorizeExchange((authorizeExchange) -> authorizeExchange.anyExchange().permitAll())
			.csrf(ServerHttpSecurity.CsrfSpec::disable)
			.build();
	}

	@Bean
	@Profile("secure")
	public SecurityWebFilterChain securityWebFilterChainSecure(ServerHttpSecurity http) {
		return http
			.authorizeExchange(
					(authorizeExchange) -> authorizeExchange.pathMatchers(this.adminServer.path("/assets/**"))
						.permitAll()
						.pathMatchers("/actuator/health/**")
						.permitAll()
						.pathMatchers(this.adminServer.path("/login"))
						.permitAll()
						.anyExchange()
						.authenticated())
			.formLogin((formLogin) -> formLogin.loginPage(this.adminServer.path("/login"))
				.authenticationSuccessHandler(loginSuccessHandler(this.adminServer.path("/"))))
			.logout((logout) -> logout.logoutUrl(this.adminServer.path("/logout"))
				.logoutSuccessHandler(logoutSuccessHandler(this.adminServer.path("/login?logout"))))
			.httpBasic(Customizer.withDefaults())
			.csrf(ServerHttpSecurity.CsrfSpec::disable)
			.build();
	}

	// The following two methods are only required when setting a custom base-path (see
	// 'basepath' profile in application.yml)
	private ServerLogoutSuccessHandler logoutSuccessHandler(String uri) {
		RedirectServerLogoutSuccessHandler successHandler = new RedirectServerLogoutSuccessHandler();
		successHandler.setLogoutSuccessUrl(URI.create(uri));
		return successHandler;
	}

	private ServerAuthenticationSuccessHandler loginSuccessHandler(String uri) {
		RedirectServerAuthenticationSuccessHandler successHandler = new RedirectServerAuthenticationSuccessHandler();
		successHandler.setLocation(URI.create(uri));
		return successHandler;
	}

	@Bean
	public Notifier notifier() {
		return (e) -> Mono.empty();
	}

	public static void main(String[] args) {
		SpringApplication.run(App.class, args);
	}

}

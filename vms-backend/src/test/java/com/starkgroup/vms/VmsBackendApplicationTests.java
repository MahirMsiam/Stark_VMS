package com.starkgroup.vms;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("h2") // tests never need a running MySQL
class VmsBackendApplicationTests {

	@Test
	void contextLoads() {
	}

}

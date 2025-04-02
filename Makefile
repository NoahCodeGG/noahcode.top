new_zh_content:
	$(eval year := $(shell date +%Y))
	$(eval month := $(shell date +%m))
	$(eval day := $(shell date +%d))
	hugo new content/posts/$(year)/$(month)/$(day)/$(name)/index.md

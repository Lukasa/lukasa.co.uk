.PHONY: publish

publish:
	jekyll build
	s3_website push
